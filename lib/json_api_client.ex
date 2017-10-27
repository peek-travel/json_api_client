defmodule JsonApiClient do
  @moduledoc """
  A client library for interacting with REST APIs that comply with
  the JSON API spec described at http://jsonapi.org
  """

  alias __MODULE__.Request
  alias __MODULE__.Middleware.Runner

  @doc "Execute a JSON API Request using HTTP GET"
  def fetch(req), do: req |> Request.method(:get) |> execute
  @doc "Error raising version of `fetch/1`"
  def fetch!(req), do: req |> Request.method(:get) |> execute!

  @doc "Execute a JSON API Request using HTTP POST"
  def create(req), do: req |> Request.method(:post) |> execute
  @doc "Error raising version of `create/1`"
  def create!(req), do: req |> Request.method(:post) |> execute!

  @doc "Execute a JSON API Request using HTTP PATCH"
  def update(req), do: req |> Request.method(:patch) |> execute
  @doc "Error raising version of `update/1`"
  def update!(req), do: req |> Request.method(:patch) |> execute!

  @doc "Execute a JSON API Request using HTTP DELETE"
  def delete(req), do: req |> Request.method(:delete) |> execute
  @doc "Error raising version of `delete/1`"
  def delete!(req), do: req |> Request.method(:delete) |> execute!

  @doc """
  Execute a JSON API Request

  Takes a JsonApiClient.Request and preforms the described request.

  Returns either a tuple with `:ok` and a `JsonApiClient.Response` struct (or
  nil) or `:error` and a `JsonApiClient.RequestError` struct depending on the
  http response code and whether the server response was valid according to the
  JSON API spec.

  | Scenario     | Server Response Valid | Return Value                                                                         |
  |--------------|-----------------------|--------------------------------------------------------------------------------------|
  | 2**          | yes                   | `{:ok, %Response{status: 2**, doc: %Document{}}`                                     |
  | 4**          | yes                   | `{:ok, %Response{status: 4**, doc: %Document{} or nil}`                              |
  | 5**          | yes                   | `{:ok, %Response{status: 5**, doc: %Document{} or nil}`                              |
  | 2**          | no                    | `{:error, %RequestError{status: 2**, message: "Invalid response body"}}`             |
  | 4**          | no                    | `{:ok, %Response{status: 4**, doc: nil}}`                                            |
  | 5**          | no                    | `{:ok, %Response{status: 3**, doc: nil}}`                                            |
  | socket error | n/a                   | `{:error, %RequestError{status: nil, message: "Error completing HTTP request econnrefused", original_error: error}}` |

  """
  def execute(req) do
    Runner.run(req)
  end

  @doc "Error raising version of `execute/1`"
  def execute!(req) do
    case execute(req) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end
end
