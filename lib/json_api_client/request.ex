defmodule JsonApiClient.Request do
  @moduledoc """
  Describes a JSON API HTTP Request
  """
  alias __MODULE__

  defstruct(
    base_url: nil,
    params: %{},
    id: nil,
    resource: nil,
    method: :get,
    headers: %{},
    options: %{},
    service_name: nil,
    attributes: %{}
  )

  @doc "Create a request"
  def new do
    %__MODULE__{}
  end

  @doc "Create a request with the given base URL"
  def new(base_url) do
    %__MODULE__{base_url: base_url}
  end

  @doc "Add an id to the request."
  def id(req, id), do: Map.put(req, :id, id)

  @doc "Specify the HTTP method for the request."
  def method(req, method), do: Map.put(req, :method, method)

  @doc "Associate a resource with this request"
  def resource(req, resource), do: Map.put(req, :resource, resource)

  @doc "Associate a service_name with this request"
  def service_name(req, service_name), do: Map.put(req, :service_name, service_name)

  @doc "Associate a path with this request"
  def path(req, %{type: _, id: _} = res), do: Map.merge(req, %{base_url: get_url(resource(req, res))})
  def path(req, path), do: Map.merge(req, %{base_url: join_url_parts([req.base_url, String.trim(path, "/")])})

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

  @doc """
  Add a a header to the request.".

      header(%Request{}, "X-My-Header", "My header value")
  """
  def header(req, header_name, header_value), do: %{req | headers: Map.put(req.headers, header_name, header_value)}

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

  @doc ~S"""
  Add query params to the request.

  Will add to existing params when called multiple times with different keys,
  but individual parameters will be overwritten. Supports nested attributes.

      iex> req = new("http://api.net") |> params(a: "foo", b: "bar")
      iex> req |> get_query_params |> URI.encode_query
      "a=foo&b=bar"

      iex> req = new("http://api.net")   \
      ...> |> params(a: "foo", b: "bar") \
      ...> |> params(a: "new", c: "baz")
      iex> req |> get_query_params |> URI.encode_query
      "a=new&b=bar&c=baz"
  """
  def params(req, list) do
    Enum.reduce(list, req, fn ({param, val}, acc) ->
      new_params = Map.put(acc.params, param, val)
      put_in(acc.params, new_params)
    end)
  end

  @doc ~S"""
  Get the url for the request

  The URL returned does not include the query string

  ## Examples

      iex> new("http://api.net") |> id("123") |> get_url
      "http://api.net/123"
      iex> post = %JsonApiClient.Resource{type: "posts", id: "123"}
      iex> new("http://api.net") |> resource(post) |> get_url
      "http://api.net/posts/123"
  """
  def get_url(%Request{base_url: base_url, id: id}) when not is_nil(id),
    do: join_url_parts [base_url, id]
  def get_url(%Request{base_url: base_url, resource: %{type: type}, method: :post}),
    do: join_url_parts [base_url, type]
  def get_url(%Request{base_url: base_url, resource: %{type: type, id: id}}),
    do: join_url_parts [base_url, type, id]
  def get_url(%Request{base_url: base_url}),
    do: base_url

  defp join_url_parts(parts) do
    parts
    |> Enum.reject(&is_nil/1)
    |> Enum.join("/")
  end

  @doc """
  Get the query parameters for the request

  Retruns an Enumerable suitable for passing to `URI.encode_query`.

  The "params" stored in the Request struct are represented as nested hashed and arrays. This function flattens out the hashes and converts the values for attributes that take lists like `incldues` and `fields` and converts them to the comma separated strings that JSON API expects.

  ## Examples

      iex> req = new("http://api.net")
      iex> req |> fields(type1: [:a, :b, :c]) |> get_query_params
      [{"fields[type1]", "a,b,c"}]
      iex> req |> params(a: %{b: %{c: "foo"}}) |> get_query_params
      [{"a[b][c]", "foo"}]
  """
  def get_query_params(%Request{params: params}) when params != %{} do
    params
    |> encode_fields
    |> encode_include
    |> UriQuery.params
  end
  def get_query_params(_req), do: []

  @doc """
  Retruns the HTTP body of the request
  """
  def get_body(%Request{method: method, resource: resource})
  when method in [:post, :patch, :put] and not is_nil(resource)
  do
    Poison.encode!(%{data: resource})
  end
  def get_body(_req), do: ""

end
