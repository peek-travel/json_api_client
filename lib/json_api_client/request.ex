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
    new_fields = fields_to_add
      |> Enum.map(fn
        {k, v} when is_list(v) -> {k, Enum.join(v, ",")}
        {k, v} -> {k, v}
      end)
      |> Enum.into(current_fields)
    params(req, fields: new_fields)
  end

  @doc """
  Specify which relationships to include

  Takes a request and the relationships you want to include.
  Relationships can be expressed as a string or a list of
  relationship strings.

      include(%Request{}, "coments.author")
      include(%Request{}, ["author", "comments.author"])
  """
  def include(req, relationships) do
    relationships = if is_list(relationships),
      do: Enum.join(relationships, ","),
      else: relationships

    params(req, include: relationships)
  end

  def sort(req, sort)    , do: params(req, sort:    sort)
  def page(req, page)    , do: params(req, page:    page)
  def filter(req, filter), do: params(req, filter:  filter)

  def params(req, list) do
    Enum.reduce(list, req, fn ({param, val}, acc) ->
      new_params = Map.put(acc.params, param, val)
      put_in(acc.params, new_params)
    end)
  end

end
