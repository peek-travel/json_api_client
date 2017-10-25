defmodule JsonApiClient.Middleware.FuseTest do
  use ExUnit.Case
  doctest JsonApiClient.Middleware.Fuse, import: true

  import Mock
  alias JsonApiClient.{Request, Response, RequestError}
  alias JsonApiClient.Middleware.Fuse

  @request %Request{}
  @service_name :my_service
  @options [
    {@service_name, {{:standard, 3, 30_000}, {:reset, 30_000}}},
    {:opts, {{:standard, 4, 40_000}, {:reset, 40_000}}}
  ]

  test "returns error and doesn not call next middleware when circuit breaker is closed" do
    {:ok, agent} = Agent.start_link fn -> 0 end
    with_mocks(
      [
        {
          :fuse, [], [
            ask: fn(_, :sync) -> :blown end,
          ]
        }
      ]
      ) do
        assert {:error, %RequestError{
          message: "Unavailable - json_api_client circuit blown",
          original_error: "Unavailable - json_api_client circuit blown",
          status: nil}} =
        Fuse.call(@request, fn request ->
          Agent.update(agent, fn count -> count + 1 end)
          assert request == @request
        end, [])

        assert Agent.get(agent, fn count -> count end) == 0
    end
  end

  test "returns OK and calls next middleware when circuit breaker is installed" do
    {:ok, agent} = Agent.start_link fn -> 0 end
    with_mocks(
      [
        {
          :fuse, [], [
            ask: fn(_, :sync) -> {:error, :not_found} end,
            install: fn(_, _) -> :ok end,
          ]
        }
      ]
      ) do
      Fuse.call(@request, fn request ->
        Agent.update(agent, fn count -> count + 1 end)
        assert request == @request
        {:ok, %Response{}}
      end, [])

      assert Agent.get(agent, fn count -> count end) == 1
    end
  end

  test "returns OK and calls next middleware when circuit breaker is opened" do
    {:ok, agent} = Agent.start_link fn -> 0 end
    with_mocks(
      [
        {
          :fuse, [], [
            ask: fn(_, :sync) -> :ok end,
          ]
        }
      ]
      ) do
      Fuse.call(@request, fn request ->
        Agent.update(agent, fn count -> count + 1 end)
        assert request == @request
        {:ok, %Response{}}
      end, [])

      assert Agent.get(agent, fn count -> count end) == 1
    end
  end

  test "melt use when error" do
    with_mocks(
      [
        {
          :fuse, [], [
            ask: fn(_, :sync) -> :ok end,
            melt: fn(_name) -> :ok end,
          ]
        }
      ]
      ) do
      Fuse.call(@request, fn _request -> {:error, %RequestError{}} end, [])
      assert called :fuse.melt("json_api_client")
    end
  end

  test "uses default name when service name is not configured" do
    check_name(@request, "json_api_client")
  end

  test "uses service as name when service name is configured" do
    check_name(Request.service_name(@request, @service_name), @service_name)
  end

  test "uses default options when service name is not configured and no global options" do
    check_options(@request, [], {{:standard, 2, 10_000}, {:reset, 60_000}})
  end

  test "uses gloal when service name is not configured and global options exist" do
    check_options(@request, @options, Keyword.get(@options, :opts))
  end

  test "uses gloal when service is configured (no confoguration) and global options exist" do
    check_options(Request.service_name(@request, :foo), @options, Keyword.get(@options, :opts))
  end

  test "uses service options when service is configured service options exist" do

    check_options(Request.service_name(@request, @service_name), @options, Keyword.get(@options, @service_name))
  end

  defp check_name(request, fuse_name) do
    with_mocks(
      [
        {
          :fuse, [], [
            ask: fn(name, :sync) ->
              assert name == fuse_name
              {:error, :not_found}
            end,
            install: fn(name, _opts) ->
              assert name == fuse_name
              :ok
            end
          ]
        }
      ]
      ) do
      Fuse.call(request, fn _env -> {:ok, %Response{}} end, @options)
    end
  end

  defp check_options(request, options, fuse_options) do
    with_mocks(
      [
        {
          :fuse, [], [
            ask: fn(_name, :sync) ->
              {:error, :not_found}
            end,
            install: fn(_name, opts) ->
              assert fuse_options == opts
              :ok
            end
          ]
        }
      ]
      ) do
      Fuse.call(request, fn _env -> {:ok, %Response{}} end, options)
    end
  end
end
