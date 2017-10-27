defmodule JsonApiClient.Middleware.Factory do
  @moduledoc false

  def middlewares do
    configured_middlewares() ++ [
      {JsonApiClient.Middleware.DefaultRequestConfig, nil},
      {JsonApiClient.Middleware.DocumentParser, nil},
      {JsonApiClient.Middleware.HTTPClient, nil}
    ]
  end

  defp configured_middlewares do
    Application.get_env(:json_api_client, :middlewares, [])
  end
end
