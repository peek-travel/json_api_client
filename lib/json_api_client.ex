defmodule JsonApiClient do
  @client_name Application.get_env(:json_api_client, :client_name)
  @timeout Application.get_env(:json_api_client, :timeout, 500)
  @version Mix.Project.config[:version]

  @moduledoc """
  Documentation for JsonApiClient.
  """

  def request(base_url) do
    %{base_url: base_url, params: %{}}
  end

  def id(req, id)        , do: Map.put(req, :resource_id, id)
  def method(req, method), do: Map.put(req, :method, method)

  def fields(req, fields)  , do: params(req, fields:  fields)
  def sort(req, sort)      , do: params(req, sort:    sort)
  def page(req, page)      , do: params(req, page:    page)
  def filter(req, filter)  , do: params(req, filter:  filter)
  def include(req, include), do: params(req, include: include)

  def params(req, list) do
    Enum.reduce(list, req, fn ({param, val}, acc) ->
      put_in(acc, [:params, param], val)
    end)
  end

  def fetch(req), do: req |> method(:get) |> execute

  def execute(req) do
    method       = Map.get(req, :method)
    base_url     = Map.get(req, :base_url)
    resource_id  = Map.get(req, :resource_id)
    url = [base_url, resource_id]
          |> Enum.reject(&is_nil/1)
          |> Enum.join("/")
    params       = Map.get(req, :params)
    data         = Map.get(req, :data)
    headers      = Map.get(req, :headers, default_headers())
    http_options = Map.get(req, :options, default_options())

    url = if params != %{},
      do: "#{url}?#{URI.encode_query UriQuery.params(params)}",
      else: url

    case HTTPoison.request(method, url, "", headers, http_options) do
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

defmodule JsonApiClient.Request do
  @moduledoc """
  Describes a JSON API HTTP Request
  """

  defstruct(
    data:     nil,
    errors:   nil,
    meta:     nil,
    jsonapi:  nil,
    links:    nil,
    included: nil,
    _query: %{},
  )
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
