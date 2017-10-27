defmodule JsonApiClient.Middleware.Fuse do
  @behaviour JsonApiClient.Middleware

  @moduledoc """
  Circuit Breaker middleware using [fuse](https://github.com/jlouis/fuse)
  ### Options
  - `service_name -> :opts` - fuse options per service
  - `:opts` - fuse options when options are not configured per service (see fuse docs for reference)

  ```elixir
  config :json_api_client,
    middlewares: [
      {JsonApiClient.Middleware.Fuse, 
        opts: {{:standard, 2, 10_000}, {:reset, 60_000}},
        service1: {{:standard, 10, 5_000}, {:reset, 120_000}},
      }
    ]
  ```

  In this example we're specifying the default fuse options with `opts` and
  then specifying different fuse options for the `service1` fuse. Fuses are
  named based on the `service_name` of the request, if present.
  """

  alias JsonApiClient.{RequestError, Request}

  @defaults {{:standard, 2, 10_000}, {:reset, 60_000}}

  def call(%Request{service_name: service_name} = request, next, options) do
    opts = options || []
    name = if is_nil(service_name), do: "json_api_client", else: service_name

    case :fuse.ask(name, :sync) do
      :ok ->
        run(request, next, name)

      :blown ->
        {:error, %RequestError {
          original_error: "Unavailable - #{name} circuit blown",
          message: "Unavailable - #{name} circuit blown",
          status: nil
        }}

      {:error, :not_found} ->
        :fuse.install(name, fuse_options(service_name, opts))
        run(request, next, name)
    end
  end

  defp fuse_options(service_name, opts) when is_nil(service_name), do: Keyword.get(opts, :opts, @defaults)
  defp fuse_options(service_name, opts), do: Keyword.get(opts, service_name, fuse_options(nil, opts))

  defp run(env, next, name) do
    case next.(env) do
      {:error, error} ->
        :fuse.melt(name)
        {:error, error}
      success ->
        success
    end
  end
end
