defmodule JsonApiClient.Request do
  @moduledoc """
  Describes a JSON API HTTP Request
  """

  defstruct(
    base_url: nil,
    params: %{},
    id: nil,
    method: :get,
    headers: [],
    options: [],
  )

  def request(base_url) do
    %__MODULE__{base_url: base_url}
  end

  def id(req, id)        , do: Map.put(req, :id, id)
  def method(req, method), do: Map.put(req, :method, method)

  def fields(req, fields)  , do: params(req, fields:  fields)
  def sort(req, sort)      , do: params(req, sort:    sort)
  def page(req, page)      , do: params(req, page:    page)
  def filter(req, filter)  , do: params(req, filter:  filter)
  def include(req, include), do: params(req, include: include)

  def params(req, list) do
    Enum.reduce(list, req, fn ({param, val}, acc) ->
      new_params = Map.put(acc.params, param, val)
      put_in(acc.params, new_params)
    end)
  end

end
