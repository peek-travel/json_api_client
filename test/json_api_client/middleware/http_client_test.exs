defmodule JsonApiClient.Middleware.HTTPClientTest do
  use ExUnit.Case
  doctest JsonApiClient.Middleware.HTTPClient, import: true

  import Mock

  alias JsonApiClient.Middleware.HTTPClient

  @response_body "body"

  setup do
    bypass  = Bypass.open

    env = %{
      method: :get,
      url: "http://localhost:#{bypass.port}/articles",
      body: "",
      headers: [{"Accept", "application/vnd.api+json"}, {"Content-Type", "application/vnd.api+json"}],
      http_options: [{:timeout, 500}, {:recv_timeout, 500}]
    }

    {:ok, bypass: bypass, env: env}
  end

  test "uses HTTPoison as underlying http client", context do
    with_mock HTTPoison, [], [request: fn(method, url, body, headers, http_options) ->
      assert method == context.env.method
      assert url == context.env.url
      assert body == context.env.body
      assert headers == context.env.headers
      assert http_options == context.env.http_options

      {:ok, %{status_code: 500, headers: [], body: ""}}
    end] do
      call_middleware(context)
    end
  end

  test "includes status_code from the HTTP response", context do
    Bypass.expect context.bypass, "GET", "/articles", fn conn ->
      conn
      |> Plug.Conn.resp(200, "")
    end

    {:ok, response} = call_middleware(context)

    assert response.status == 200
  end

  test "includes headers from the HTTP response", context do
    Bypass.expect context.bypass, "GET", "/articles", fn conn ->
      conn
      |> Plug.Conn.resp(200, "")
      |> Plug.Conn.put_resp_header("x-test-header", "42")
    end

    {:ok, response} = call_middleware(context)

    assert Enum.member?(response.headers, {"x-test-header", "42"})
  end

  test "includes doc from the HTTP response", context do
    Bypass.expect context.bypass, "GET", "/articles", fn conn ->
      Plug.Conn.resp(conn, 200, @response_body)
    end

    {:ok, response} = call_middleware(context)

    assert response.doc == @response_body
  end

  defp call_middleware(context) do
    HTTPClient.call(context.env, nil, nil)
  end
end
