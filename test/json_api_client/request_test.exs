defmodule JsonApiClient.RequestTest do
  use ExUnit.Case
  doctest JsonApiClient.Request, import: true
  alias JsonApiClient.Request
  import JsonApiClient.Request

  describe "params()" do
    test "adds a single value to the params map" do
      assert %Request{params: %{a: 1}} = params(%Request{}, a: 1)
    end
    test "adds multiple values to the params map" do
      assert %Request{params: %{a: 1, b: 2}} = params(%Request{}, a: 1, b: 2)
    end
  end

  describe "fields()" do
    test "fields can be expressed as a string" do
      req = fields(%Request{}, sometype: "name,email")
      assert get_query_params(req) == [{"fields[sometype]", "name,email"}]
    end

    test "fields can be expressed as a list of strings" do
      req = fields(%Request{}, sometype: ~w(name email))
      assert get_query_params(req) == [{"fields[sometype]", "name,email"}]
    end

    test "fields can be expressed as a list of atoms" do
      req = fields(%Request{}, sometype: [:name, :email])
      assert get_query_params(req) == [{"fields[sometype]", "name,email"}]
    end

    test "fields for multiple types accepted in multiple calls" do
      req = %Request{}
      |> fields(type1: [:name, :email])
      |> fields(type2: [:age])

      assert get_query_params(req) == [
        {"fields[type1]", "name,email"},
        {"fields[type2]", "age"},
      ]
    end

    test "fields for multiple types accepted in a single call" do
      req = fields(%Request{},
        type1: [:name, :email],
        type2: "age",
      )
      assert get_query_params(req) == [
        {"fields[type1]", "name,email"},
        {"fields[type2]", "age"},
      ]
    end
  end

  test "sort", do: assert_updates_param(:sort)
  test "page", do: assert_updates_param(:page)
  test "filter", do: assert_updates_param(:filter)

  describe "include" do
    test "accepts a single relationship to include" do
      req = include(%Request{}, "comments.author")
      assert get_query_params(req) == [{"include", "comments.author"}]
    end

    test "accepts multiple relationships to include" do
      req = include(%Request{}, ["comments.author", "author"])
      assert get_query_params(req) == [{"include", "comments.author,author"}]
    end

    test "multiple calls are addative" do
      req = %Request{}
      |> include("comments.author")
      |> include("author")

      assert get_query_params(req) == [{"include", "comments.author,author"}]
    end
  end

  def assert_updates_param(field_name) do
    assert %{params: %{^field_name => "someval"}} =
      apply(Request, field_name, [%Request{}, "someval"])
  end

  test "id", do: assert_updates_field(:id)
  test "resource", do: assert_updates_field(:resource)
  test "method", do: assert_updates_field(:method)

  def assert_updates_field(field_name) do
    assert %{^field_name => "someval"} =
      apply(Request, field_name, [%Request{}, "someval"])
  end

  describe "get_body()" do
    test "uses resource for POST & PATCH" do
      for http_method <- [:post, :patch] do
        parsed_body = new("http://api.net")
        |> resource(%JsonApiClient.Resource{type: "users", attributes: %{name: "foo"}})
        |> method(http_method)
        |> get_body
        |> Poison.decode!

        assert %{"data" => %{"type" => "users", "attributes" => %{"name" => "foo"}}} = parsed_body
      end
    end
    test "GET & DELETE" do
      for http_method <- [:get, :delete] do
        body = new("http://api.net")
        |> resource(%JsonApiClient.Resource{type: "users", attributes: %{name: "foo"}})
        |> method(http_method)
        |> get_body

        assert body == ""
      end
    end

    test "returns empty string if resource not present" do
      for http_method <- [:delete, :post, :patch, :get, :delete] do
        assert "" = new("http://api.net") |> method(http_method) |> get_body
      end
    end
  end

  describe "get_url()" do
    test "when resource does not have id" do
      url = new("http://api.net")
      |> resource(%JsonApiClient.Resource{type: "articles"})
      |> get_url

      assert "http://api.net/articles" = url
    end

    test "when request method is a post" do
      url = new("http://api.net")
      |> resource(%JsonApiClient.Resource{type: "articles", id: "1", attributes: %{comment: "some_comment"}})
      |> method(:post)
      |> get_url

      assert "http://api.net/articles" = url
    end

    test "when resource has id" do
      url = new("http://api.net")
      |> resource(%JsonApiClient.Resource{type: "articles", id: "1"})
      |> get_url

      assert "http://api.net/articles/1" = url
    end

    test "when getting a nested resource" do
      url = new("http://api.net")
      |> path(%JsonApiClient.Resource{type: "notes", id: "123"})
      |> resource(%JsonApiClient.Resource{type: "replies", id: "345"})
      |> get_url

      assert "http://api.net/notes/123/replies/345" = url
    end

    test "when creating a nested resource" do
      url = new("http://api.net")
      |> path(%JsonApiClient.Resource{type: "notes", id: "123"})
      |> resource(%JsonApiClient.Resource{type: "replies", id: "345", attributes: %{body: "body"}})
      |> method(:post)
      |> get_url

      assert "http://api.net/notes/123/replies" = url
    end
  end

  describe "path()" do
    test "when resource does not have id" do
      req = new("http://api.net")
      |> path(%JsonApiClient.Resource{type: "articles"})

      assert "http://api.net/articles" = req.base_url
    end

    test "when resource has id" do
      req = new("http://api.net")
      |> path(%JsonApiClient.Resource{type: "articles", id: "1"})

      assert "http://api.net/articles/1" = req.base_url
    end

    test "when path is a string" do
      req = new("http://api.net")
      |> path("foo/bar")

      assert "http://api.net/foo/bar" = req.base_url
    end

    test "when path has a `/` at the beginning" do
      req = new("http://api.net")
      |> path("/foo/bar")

      assert "http://api.net/foo/bar" = req.base_url
    end

    test "when path has a `/` at the and" do
      req = new("http://api.net")
      |> path("/foo/bar/")

      assert "http://api.net/foo/bar" = req.base_url
    end
  end

  describe "header()" do
    test "when new values is added" do
      req = new("http://api.net")
      |> header("X-My-Header", "My header")

      assert %Request{headers: %{"X-My-Header" => "My header"}} = req
    end

    test "when a header is already added" do
      req = new("http://api.net")
      |> header("X-My-Header", "My header")
      |> header("X-My-Header", "My header 2")

      assert %Request{headers: %{"X-My-Header" => "My header 2"}} = req
    end
  end

  describe "service_name" do
    test "sents new value" do
      req = new("http://api.net")
      |> service_name("my service")

      assert %Request{service_name: "my service"} = req
    end
  end

  describe "new" do
    test "creates an empty request" do
      assert %Request{} == new()
    end
  end
end
