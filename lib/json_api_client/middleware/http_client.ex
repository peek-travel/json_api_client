defmodule JsonApiClient.Middleware.HTTPClient do
  @behaviour JsonApiClient.Middleware
  @moduledoc """
  HTTP client Middleware based on HTTPoison library.
  """

  alias JsonApiClient.{Response, RequestError}

  def call(%{method: method, url: url, body: body, headers: headers, http_options: http_options}, _, _) do
    case HTTPoison.request(method, url, body, headers, http_options) do
      {:ok, response} -> {:ok, %Response{
        status: response.status_code,
        headers: response.headers,
        doc: response.body
      }}
      {:error, error} -> {:error, %RequestError{
        original_error: error,
        message: "Error completing HTTP request: #{error.reason}"
      }}
    end
  end
end
