defmodule JsonApiClient.Middleware.DocumentParserTest do
  use ExUnit.Case
  doctest JsonApiClient.Middleware.DocumentParser, import: true

  alias JsonApiClient.{Response, RequestError}
  alias JsonApiClient.Middleware.DocumentParser

  @resource_doc %JsonApiClient.Document{
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

  @request %{path: "foo"}
  @succses_response %Response{
    doc: Poison.encode!(@resource_doc),
    status: 200,
    headers: [{:foo, :bar}],
  }
  @succses_result {:ok, @succses_response}

  @error %RequestError{original_error: "unknown"}

  test "when the doc is OK" do
    assert {:ok, %Response{
      doc: doc,
      status: 200,
      headers: [foo: :bar],
      }
    } = DocumentParser.call(@request, fn  request ->
      assert request == @request
      @succses_result
    end, %{})

    assert @resource_doc == doc
  end

  test "when the next Middleware response is error" do
    assert {
      :error,
      %RequestError{
        original_error: "unknown",
      }
    } = DocumentParser.call(@request, fn _request -> {:error, @error} end, %{})
  end

  test "when a response body is empty" do
    assert {:ok, %Response{
      doc: nil,
      status: 200,
      headers: [foo: :bar],
    }} = DocumentParser.call(@request, fn _request -> {:ok, %{@succses_response | doc: ""}} end, %{})
  end

  test "when a response cannot be parsed" do
    assert {:error, %RequestError{
      original_error: _,
      message: message,
    }} = DocumentParser.call(@request, fn _request -> {:ok, %{@succses_response | doc: "invalid"}} end, %{})

    assert message =~ "Error Parsing JSON API Document"
  end
end
