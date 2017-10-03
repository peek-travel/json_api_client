defmodule JsonApiClient.Request do
  @moduledoc """
  Describes a JSON API HTTP Request
  """
  alias __MODULE__

  defstruct(
    base_url: nil,
    params: %{},
    id: nil,
    method: :get,
    headers: [],
    options: [],
  )

  def url(%Request{base_url: base_url, id: id}) do
    [base_url, id]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("/")
  end

  def query_params(%Request{params: params}) when params != %{} do
    params
    |> encode_fields
    |> encode_include
    |> UriQuery.params
  end
  def query_params(_req), do: []

  @doc "Create a request with the given base URL"
  def new(base_url) do
    %__MODULE__{base_url: base_url}
  end

  @doc "Add an id to the request."
  def id(req, id), do: Map.put(req, :id, id)

  @doc "Specify the HTTP method for the request."
  def method(req, method), do: Map.put(req, :method, method)

  @doc """
  Specify which fields to include

  Takes a request and the fields you want to include as a keyword list where
  the keys are types and the values are a comma separated string or a list of
  field names.

      fields(%Request{}, user: ~(name, email), comment: ~(body))
      fields(%Request{}, user: "name,email", comment: "body")
  """
  def fields(req, fields_to_add) do
    current_fields = req.params[:fields] || %{}
    new_fields = Enum.into(fields_to_add, current_fields)
    params(req, fields: new_fields)
  end

  defp encode_fields(%{fields: %{} = fields} = params) do
    encoded_fields = fields
      |> Enum.map(fn
        {k, v} when is_list(v) -> {k, Enum.join(v, ",")}
        {k, v} -> {k, v}
      end)
      |> Enum.into(%{})
    Map.put(params, :fields, encoded_fields)
  end
  defp encode_fields(params), do: params

  @doc """
  Specify which relationships to include

  Takes a request and the relationships you want to include.
  Relationships can be expressed as a string or a list of
  relationship strings.

      include(%Request{}, "coments.author")
      include(%Request{}, ["author", "comments.author"])
  """
  def include(req, relationship_list)
  when is_list(relationship_list)
  do
    existring_relationships = req.params[:include] || []
    params(req, include: existring_relationships ++ relationship_list)
  end
  def include(req, relationships)
  when is_binary(relationships) or is_atom(relationships)
  do
    existring_relationships = req.params[:include] || []
    params(req, include: existring_relationships ++ [relationships])
  end
  defp encode_include(%{include: include} = params) when is_list(include) do
    encoded_include = include
    |> List.flatten
    |> Enum.join(",")
    Map.put(params, :include, encoded_include)
  end
  defp encode_include(include), do: include

  @doc "Specify the sort param for the request."
  def sort(req, sort), do: params(req, sort: sort)
  @doc "Specify the page param for the request."
  def page(req, page), do: params(req, page: page)
  @doc "Specify the filter param for the request."
  def filter(req, filter), do: params(req, filter: filter)

  @doc """
  Add query params to the request.

  Will add to existing params when called multiple times. Supports nested
  attributes.

      # to add "custom_param1=foo&custom_param2=bar" to the query...
      params(%Request{}, custom_param1: "foo", custom_param2: "bar")
      # to add "foo[bar]=baz" to the query...
      params(%Request{}, foo: %{bar: %{baz: 3}})
  """
  def params(req, list) do
    Enum.reduce(list, req, fn ({param, val}, acc) ->
      new_params = Map.put(acc.params, param, val)
      put_in(acc.params, new_params)
    end)
  end

end
