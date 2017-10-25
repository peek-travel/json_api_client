defmodule JsonApiClient.Middleware.StatsTracker do
  @moduledoc """
  Stats Tracking Middleware

  ### Options
  - `:name` - name of the stats (used in logging)
  - `:log` - The log level to log at. No logging is done if `false`. Defaults to `false`

  Middleware that adds stats data to response, and optionally logs it.

  The `JsonApiClient.Middleware.StatsTracker` middleware provides
  instrumentation for your requests. `StatsTracker` can be added to the
  middleware stack to track the time spent in the middleware that comes after
  it and add that data to the `Response` struct. If `log` is spoecified in the
  options `StatsTracker` will then log all stats data in the `Response` struct
  at the specified log level. Here's a sample configuration to add stats
  tracking to the http request and parsing.

  ```elixir
  config :json_api_client,
    middlewares: [
      {JsonApiClient.Middleware.StatsLogger, name: :parse_response, log: :info},
      {JsonApiClient.Middleware.DocumentParser, nil},
      {JsonApiClient.Middleware.StatsTracker, name: :http_request},
      {JsonApiClient.Middleware.HTTPClient, nil},
    ]
  ```

  That would cause something like the following to be logged on each request:

  ```
  15:57:30.198 [info]  total_ms=73.067 url=http://example.com/articles/123 parse_response_ms=7.01 http_request=66.057
  ```

  Note that the `StatsTracker` middleware tracks the time spent in all the
  middleware that comes after it in the stack. When it logs this data it
  subtacts the time recorded by the next StatsTracker in the stack so that you
  can see the time spent in distinct potions of the middleware stack.

  Consider this stack, for example:

  ```elixir
  config :json_api_client,
    middlewares: [
      {JsonApiClient.Middleware.StatsTracker, name: :custom_middleware, log: :info}, 
      {CustomMiddleware1, nil},
      {CustomMiddleware2, nil},
      {CustomMiddleware3, nil},
      {JsonApiClient.Middleware.StatsTracker, name: :request_and_parsing},
      {JsonApiClient.Middleware.DocumentParser, nil},
      {JsonApiClient.Middleware.HTTPClient, nil},
    ]
  ```

  This will log the time spent in all three custom loggers as one value and the
  time spent preforming the http request and parsing the response as another.

  ```
  15:57:30.198 [info]  total_ms=100 url=http://example.com/articles/123 custom_middleware_ms=12 request_and_parsing=88
  ```
  """
  require Logger

  def call(request, next, opts) do
    name = Access.get(opts, :name)
    log_level = Access.get(opts, :log, false)

    {microseconds, {status, response}} = :timer.tc fn -> next.(request) end
    timer_tuple = {name, microseconds / 1_000}

    attributes = response.attributes
    |> update_in([:stats], &(&1 || %{}))
    |> update_in([:stats, :timers], &(&1 || []))
    |> update_in([:stats, :timers], &[timer_tuple | &1])

    response = %{response | attributes: attributes}

    log_level && log_stats(request, response, log_level)

    {status, response}
  end

  defp log_stats(request, response, log_level) do
    stats = []
    |> Enum.concat(stats_from_request(request))
    |> Enum.concat(stats_from_response(response))

    log stats, log_level
  end

  @doc false
  def stats_from_response(response) do
    timers = get_in(response.attributes, [:stats, :timers]) || []
    [{_, total_ms} | _] = timers

    {stats, _} = Enum.reduce(Enum.reverse(timers), {[], 0}, fn ({name, ms}, {stats, ms_spent_elsewhere}) ->
      {[{:"#{name}_ms", ms - ms_spent_elsewhere} | stats], ms}
    end)

    [{:total_ms, total_ms} | stats]
  end

  @doc false
  def stats_from_request(request) do
    [url: request.url]
  end

  defp log(stats, log_level) do
    Logger.log log_level, fn ->
      to_logfmt(stats)
    end
  end

  defp to_logfmt(enum) do
    enum
    |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
    |> Enum.join(" ")
  end

end
