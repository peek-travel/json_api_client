defmodule JsonApiClient.Middleware.DefaultRequestConfigTest do
  use ExUnit.Case
  doctest JsonApiClient.Middleware.DefaultRequestConfig, import: true

  import Mock
  alias JsonApiClient.Request
  alias JsonApiClient.Middleware.DefaultRequestConfig

  test "calls the next middleware" do
    with_mocks(
      [
        {
          RequestConfigMockMiddleware, [], [
            call: fn(_req, _next, _options) -> nil end,
          ]
        }
      ]
      ) do
        DefaultRequestConfig.call(%Request{}, fn req -> RequestConfigMockMiddleware.call(req, nil, nil) end, nil)
        assert called RequestConfigMockMiddleware.call(:_, nil, nil)
    end
  end

  test "adds default headers" do
    check_request(fn req ->
      assert %{
        "Accept"       => "application/vnd.api+json",
        "Content-Type" => "application/vnd.api+json",
        "User-Agent"   => user_agent
      } = req.headers

      refute is_nil user_agent
    end)
  end

  test "uses specified header value instead of default value" do
    check_request(%Request{headers: %{"Accept" => "json"}}, fn req ->
      assert %{
        "Accept"       => "json",
        "Content-Type" => "application/vnd.api+json",
        "User-Agent"   => user_agent
      } = req.headers

      refute is_nil user_agent
    end)
  end

  test "adds default options" do
    check_request(fn req ->
      assert %{
        timeout: timeout,
        recv_timeout: recv_timeout,
      } = req.options

      assert is_number timeout
      assert is_number recv_timeout
    end)
  end

  test "uses specified option value instead of default value" do
    check_request(%Request{options: %{timeout: "bar", recv_timeout: "foo"}}, fn req ->
      assert %{
        timeout: "bar",
        recv_timeout: "foo",
      } = req.options
    end)
  end

  defp check_request(request \\ %Request{}, assert_fn) do
    DefaultRequestConfig.call(request, assert_fn, nil)
  end
end

defmodule RequestConfigMockMiddleware do
  @behaviour JsonApiClient.Middleware
  def call(_reqenv, _next, _options) do end
end