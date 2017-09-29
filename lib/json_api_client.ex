defmodule JsonApiClient do
  @moduledoc """
  Documentation for JsonApiClient.
  """

  @client_name Application.get_env(:json_api_client, :client_name)
  @timeout Application.get_env(:json_api_client, :timeout, 500)
  @version Mix.Project.config[:version]

  alias __MODULE__.Request

  def fetch(req), do: req |> Request.method(:get) |> execute

  def execute(req) do
    url = [req.base_url, req.id]
          |> Enum.reject(&is_nil/1)
          |> Enum.join("/")
    headers      = req.headers ++ default_headers()
    http_options = req.options ++ default_options()

    url = if req.params != %{},
      do: "#{url}?#{URI.encode_query UriQuery.params(req.params)}",
      else: url

    case HTTPoison.request(req.method, url, "", headers, http_options) do
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, :not_found}
      {:ok, resp} -> {:ok, atomize_keys(Poison.decode!(resp.body))}
      {:error, err} -> {:error, err}
    end
  end

  def atomize_keys(map) when is_map(map) do
    for {key, val} <- map, into: %{} do
      {String.to_atom(key), atomize_keys(val)}
    end
  end
  def atomize_keys(list) when is_list(list), do: Enum.map(list, &atomize_keys/1)
  def atomize_keys(val), do: val

  defp default_options do
    [timeout: timeout(), recv_timeout: timeout()]
  end

  defp default_headers do
    %{
      "Accept"       => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "User-Agent"   => user_agent()              ,
    }
  end

  defp user_agent do
    "ExApiClient/" <> @version <> "/" <> @client_name
  end

  defp timeout do
    @timeout
  end
end

defmodule JsonApiClient.Resource do
  @moduledoc """
  JSON API Resource Object
  http://jsonapi.org/format/#document-resource-objects
  """

  defstruct(
    id:            nil,
    type:          nil,
    attributes:    nil,
    relationships: nil,
    meta:          nil,
  )
end

defmodule JsonApiClient.Links do
  @moduledoc """
  JSON API Links Object
  http://jsonapi.org/format/#document-links
  """

  defstruct self: nil, related: nil
end
