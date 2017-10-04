defmodule JsonApiClientTest do
  use ExUnit.Case
  doctest JsonApiClient, import: true

  import JsonApiClient
  import JsonApiClient.Request
  alias JsonApiClient.{Request, Resource}

  setup do
    bypass = Bypass.open

    {:ok, bypass: bypass, url: "http://localhost:#{bypass.port}"}
  end

  test "get a resource", context do
    doc = single_resource_doc()
    Bypass.expect context.bypass, "GET", "/articles/123", fn conn ->
      assert_has_json_api_headers(conn)
      Plug.Conn.resp(conn, 200, Poison.encode! doc)
    end

    assert {:ok, doc} == Request.new(context.url <> "/articles")
    |> id("123")
    |> method(:get)
    |> execute

    assert {:ok, doc} == Request.new(context.url <> "/articles")
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

    assert {:ok, doc} == Request.new(context.url <> "/articles")
    |> fields(articles: "title,topic", authors: "first-name,last-name,twitter")
    |> include(:author)
    |> sort(:id)
    |> page(size: 10, number: 1)
    |> filter(published: true)
    |> params(custom1: 1, custom2: 2)
    |> fetch
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

    assert {:ok, doc} == Request.new(context.url)
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

    assert {:ok, doc} == Request.new(context.url)
    |> resource(new_article)
    |> update
  end

  def single_resource_doc do
    %{
      links: %{
        self: "http://example.com/articles/1"
      },
      data: %{
        type: "articles",
        id: "1",
        attributes: %{
          title: "JSON API paints my bikeshed!"
        },
        relationships: %{
          author: %{
            links: %{
              related: "http://example.com/articles/1/author"
            }
          }
        }
      }
    }
  end

  def multiple_resource_doc do
    %{
      links: %{
        self: "http://example.com/articles"
      },
      data: [%{
        type: "articles",
        id: "1",
        attributes: %{
          title: "JSON API paints my bikeshed!",
          category: "json-api",
        },
        relationships: %{
          author: %{
            links: %{
              self: "http://example.com/articles/1/relationships/author",
              related: "http://example.com/articles/1/author"
            },
            data: %{ type: "people", id: "9" }
          },
        }	
      }, %{
        type: "articles",
        id: "2",
        attributes: %{
          title: "Rails is Omakase",
          category: "rails",
        },
        relationships: %{
          author: %{
            links: %{
              self: "http://example.com/articles/1/relationships/author",
              related: "http://example.com/articles/1/author"
            },
            data: %{ type: "people", id: "9" }
          },
        }	
      }],
      included: [%{
        type: "people",
        id: "9",
        attributes: %{
          "first-name": "Dan",
          "last-name": "Gebhardt",
          twitter: "dgeb"
        },
        links: %{
          self: "http://example.com/people/9"
        }
      }]
    }
  end

  def assert_has_json_api_headers(conn) do
    headers = for {name, value} <- conn.req_headers, do: {String.to_atom(name), value}

    assert Keyword.get(headers, :accept) == "application/vnd.api+json"
    assert Keyword.get(headers, :"content-type") == "application/vnd.api+json"
    assert Keyword.get(headers, :"user-agent") |> String.starts_with?("ExApiClient")
  end
end
