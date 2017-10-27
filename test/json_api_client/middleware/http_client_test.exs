defmodule JsonApiClient.Middleware.HTTPClientTest do
  use ExUnit.Case
  doctest JsonApiClient.Middleware.HTTPClient, import: true

  import Mock

  alias JsonApiClient.{Request, Resource}
  alias JsonApiClient.Middleware.HTTPClient

  @response_body "body"

  setup do
    bypass  = Bypass.open

    new_article = %Resource{
      type: "articles",
      attributes: %{
        title: "JSON API paints my bikeshed!",
      }
    }

    req = %Request{
      method: :post,
      base_url: "http://localhost:#{bypass.port}",
      resource: new_article,
      params: %{filter: "value1"},
      headers: %{accept: "application/vnd.api+json"},
      options: %{timeout: 500, recv_timeout: 500}
    }

    {:ok, bypass: bypass, req: req}
  end

  test "uses HTTPoison as underlying http client", context do
    with_mock HTTPoison, [], [request: fn(method, url, body, headers, http_options) ->
      assert method == context.req.method
      assert url == Request.get_url(context.req)
      assert body == Request.get_body(context.req)
      assert headers == context.req.headers |> Enum.into([])
      assert context.req.options
      |> Map.put(:params, Request.get_query_params(context.req))
      |> Enum.into([]) == http_options

      {:ok, %{status_code: 500, headers: [], body: ""}}
    end] do
      call_middleware(context)
    end
  end

  test "includes status_code from the HTTP response", context do
    Bypass.expect context.bypass, "POST", "/articles", fn conn ->
      conn
      |> Plug.Conn.resp(200, "")
    end

    {:ok, response} = call_middleware(context)

    assert response.status == 200
  end

  test "includes headers from the HTTP response", context do
    Bypass.expect context.bypass, "POST", "/articles", fn conn ->
      conn
      |> Plug.Conn.resp(200, "")
      |> Plug.Conn.put_resp_header("x-test-header", "42")
    end

    {:ok, response} = call_middleware(context)

    assert Enum.member?(response.headers, {"x-test-header", "42"})
  end

  test "includes doc from the HTTP response", context do
    Bypass.expect context.bypass, "POST", "/articles", fn conn ->
      Plug.Conn.resp(conn, 200, @response_body)
    end

    {:ok, response} = call_middleware(context)

    assert response.doc == @response_body
  end

  defp call_middleware(context) do
    HTTPClient.call(context.req, nil, nil)
  end
end
