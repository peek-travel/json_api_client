defmodule JsonApiClientTest do
  use ExUnit.Case
  doctest JsonApiClient, import: true

  import JsonApiClient
  import JsonApiClient.Request
  alias JsonApiClient.{Request, Resource, Response, RequestError}

  setup do
    bypass = Bypass.open

    {:ok, bypass: bypass, url: "http://localhost:#{bypass.port}"}
  end

  test "includes status and headers from the HTTP response", context do
    Bypass.expect context.bypass, "GET", "/articles/123", fn conn ->
      conn 
      |> Plug.Conn.resp(200, "")
      |> Plug.Conn.put_resp_header("X-Test-Header", "42")
    end

    {:ok, response} = fetch Request.new(context.url <> "/articles/123")

    assert response.status == 200
    assert Enum.member?(response.headers, {"X-Test-Header", "42"})
  end

  test "get a resource", context do
    doc = single_resource_doc()
    Bypass.expect context.bypass, "GET", "/articles/123", fn conn ->
      assert_has_json_api_headers(conn)
      Plug.Conn.resp(conn, 200, Poison.encode! doc)
    end

    assert {:ok, %Response{status: 200, doc: ^doc}} = Request.new(context.url <> "/articles")
    |> id("123")
    |> method(:get)
    |> execute

    assert {:ok, %Response{status: 200, doc: ^doc}} = Request.new(context.url <> "/articles")
    |> id("123")
    |> fetch
  end

  test "get a list of resources", context do
    doc = multiple_resource_doc()
    Bypass.expect context.bypass, fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert %{
        "fields" => %{
          "articles" => "title,topic",
          "authors" => "first-name,last-name,twitter",
        },
        "include" => "author",
        "sort" => "id",
        "page" => %{"size" => "10", "number" => "1"},
        "filter" => %{"published" => "true"},
        "custom1" => "1",
        "custom2" => "2",
      } = conn.query_params
      assert_has_json_api_headers(conn)
      Plug.Conn.resp(conn, 200, Poison.encode! doc)
    end

    assert {:ok, %Response{status: 200, doc: ^doc}} = Request.new(context.url <> "/articles")
    |> fields(articles: "title,topic", authors: "first-name,last-name,twitter")
    |> include(:author)
    |> sort(:id)
    |> page(size: 10, number: 1)
    |> filter(published: true)
    |> params(custom1: 1, custom2: 2)
    |> fetch
  end

  test "delete a resource", context do
    Bypass.expect context.bypass, "DELETE", "/articles/123", fn conn ->
      assert_has_json_api_headers(conn)
      Plug.Conn.resp(conn, 204, "")
    end

    assert {:ok, %Response{status: 204, doc: nil}} = Request.new(context.url)
    |> resource(%Resource{type: "articles", id: "123"})
    |> delete

    assert {:ok, %Response{status: 204, doc: nil}} = Request.new(context.url <> "/articles")
    |> id("123")
    |> delete
  end

  test "create a resource", context do
    doc = single_resource_doc()
    Bypass.expect context.bypass, "POST", "/articles", fn conn ->
      assert_has_json_api_headers(conn)

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{
        "data" => %{
          "type" => "articles",
          "attributes" => %{
            "title" => "JSON API paints my bikeshed!",
          },
        }
      } = Poison.decode! body

      Plug.Conn.resp(conn, 201, Poison.encode! doc)
    end

    new_article = %Resource{
      type: "articles",
      attributes: %{
        title: "JSON API paints my bikeshed!",
      }
    }

    assert {:ok, %Response{status: 201, doc: ^doc}} = Request.new(context.url)
    |> resource(new_article)
    |> create
  end

  test "update a resource", context do
    doc = single_resource_doc()
    Bypass.expect context.bypass, "PATCH", "/articles/123", fn conn ->
      assert_has_json_api_headers(conn)

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert %{
        "data" => %{
          "type" => "articles",
          "attributes" => %{
            "title" => "JSON API paints my bikeshed!",
          },
        }
      } = Poison.decode! body

      Plug.Conn.resp(conn, 200, Poison.encode! doc)
    end

    new_article = %Resource{
      type: "articles",
      id: "123",
      attributes: %{
        title: "JSON API paints my bikeshed!",
      }
    }

    assert {:ok, %Response{status: 200, doc: ^doc}} = Request.new(context.url)
    |> resource(new_article)
    |> update
  end

  describe "Error Contidions" do
    test "HTTP success codes with invalid Documents", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "this is not json")
      end

      assert {:error, %JsonApiClient.RequestError{status: 200}} = fetch(Request.new(context.url <> "/"))
    end

    test "HTTP error codes with no content", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 422, "")
      end

      assert {:ok, %Response{status: 422, doc: nil}} = fetch(Request.new(context.url <> "/"))
    end

    test "HTTP error codes with valid Documents", context do
      doc = error_doc()
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 422, Poison.encode! doc)
      end

      assert {:ok, %Response{status: 422, doc: ^doc}} = fetch(Request.new(context.url <> "/"))
    end

    test "Failed TCP/HTTP connection", context do
      Bypass.down(context.bypass)

      assert {:error, %RequestError{
        original_error: %{reason: reason},
        status: nil,
        reason: reason,
      }} = fetch(Request.new(context.url <> "/"))
    end
  end

  def single_resource_doc do
    %JsonApiClient.Document{
      links: %JsonApiClient.Links{
        self: "http://example.com/articles/1"
      },
      data: %JsonApiClient.Resource{
        type: "articles",
        id: "1",
        attributes: %{
          "title" => "JSON API paints my bikeshed!"
        },
        relationships: %{
          "author" => %JsonApiClient.Relationship{
            links: %JsonApiClient.Links{
              related: "http://example.com/articles/1/author"
            }
          }
        }
      }
    }
  end

  def multiple_resource_doc do
    %JsonApiClient.Document{
      links: %JsonApiClient.Links{
        self: "http://example.com/articles"
      },
      data: [%JsonApiClient.Resource{
        type: "articles",
        id: "1",
        attributes: %{
          "title" => "JSON API paints my bikeshed!",
          "category" => "json-api",
        },
        relationships: %{
          "author" => %JsonApiClient.Relationship{
            links: %JsonApiClient.Links{
              self: "http://example.com/articles/1/relationships/author",
              related: "http://example.com/articles/1/author"
            },
            data: %JsonApiClient.ResourceIdentifier{ type: "people", id: "9" }
          },
        }	
      }, %JsonApiClient.Resource{
        type: "articles",
        id: "2",
        attributes: %{
          "title" => "Rails is Omakase",
          "category" => "rails",
        },
        relationships: %{
          "author" => %JsonApiClient.Relationship{
            links: %JsonApiClient.Links{
              self: "http://example.com/articles/1/relationships/author",
              related: "http://example.com/articles/1/author"
            },
            data: %JsonApiClient.ResourceIdentifier{ type: "people", id: "9" }
          },
        }	
      }],
      included: [%JsonApiClient.Resource{
        type: "people",
        id: "9",
        attributes: %{
          "first-name" => "Dan",
          "last-name" => "Gebhardt",
          "twitter" => "dgeb",
        },
        links: %JsonApiClient.Links{
          self: "http://example.com/people/9"
        }
      }]
    }
  end

  describe "dangerous execution functions raise erorrs on error" do
    setup context do
      Bypass.down(context.bypass)
      [request: Request.new(context.url <> "/articles")]
    end

    test "execute!", %{request: req}, do: assert_raise RequestError, fn -> execute! req end
    test "fetch!"  , %{request: req}, do: assert_raise RequestError, fn -> fetch!   req end
    test "update!" , %{request: req}, do: assert_raise RequestError, fn -> update!  req end
    test "create!" , %{request: req}, do: assert_raise RequestError, fn -> create!  req end
    test "delete!" , %{request: req}, do: assert_raise RequestError, fn -> delete!  req end
  end

  describe "dangerous execution functions return Response on success" do
    setup context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, Poison.encode! multiple_resource_doc())
      end
      [request: Request.new(context.url <> "/articles")]
    end

    test "execute!", %{request: req}, do: assert %Response{} = execute! req
    test "fetch!"  , %{request: req}, do: assert %Response{} = fetch!   req
    test "update!" , %{request: req}, do: assert %Response{} = update!  req
    test "create!" , %{request: req}, do: assert %Response{} = create!  req
    test "delete!" , %{request: req}, do: assert %Response{} = delete!  req
  end

  def error_doc do
    %JsonApiClient.Document{
      errors: [
	%JsonApiClient.Error{
	  status: "422",
	  source: %JsonApiClient.ErrorSource{
            pointer: "/data/attributes/first-name" 
          },
	  title:  "Invalid Attribute",
	  detail: "First name must contain at least three characters."
	}
      ]
    }
  end

  def assert_has_json_api_headers(conn) do
    headers = for {name, value} <- conn.req_headers, do: {String.to_atom(name), value}

    assert Keyword.get(headers, :accept) == "application/vnd.api+json"
    assert Keyword.get(headers, :"content-type") == "application/vnd.api+json"
    assert Keyword.get(headers, :"user-agent") |> String.starts_with?("ExApiClient")
  end
end
