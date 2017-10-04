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
end
