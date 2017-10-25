defmodule JsonApiClient.Middleware.FactoryTest do
  use ExUnit.Case
  doctest JsonApiClient.Middleware.Factory, import: true

  alias JsonApiClient.Middleware.Factory

  test "includes configured Middleware (DocumentParser and HTTPClient Middleware are the last)" do
    middlewares = Application.get_env(:json_api_client, :middlewares, [])
    configured  = {JsonApiClient.Middleware.Fuse, [{:opts, {{:standard, 2, 10_000}, {:reset, 60_000}}}]}

    Mix.Config.persist(json_api_client: [middlewares: [configured]])

    assert Factory.middlewares() == [configured, {JsonApiClient.Middleware.DocumentParser, nil}, {JsonApiClient.Middleware.HTTPClient, nil}]

    Mix.Config.persist(json_api_client: [middlewares: [middlewares]])
  end
end