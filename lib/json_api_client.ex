defmodule JsonApiClient do
  @moduledoc """
  A client library for interacting with REST APIs that comply with
  the JSON API spec described at http://jsonapi.org
  """

  @client_name Application.get_env(:json_api_client, :client_name)
  @timeout Application.get_env(:json_api_client, :timeout, 500)
  @version Mix.Project.config[:version]

  alias __MODULE__.{Request, RequestError, Response, Parser}

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
    with {:ok, response} <- do_request(req),
         {:ok, parsed}   <- parse_response(response)
    do
      {:ok, parsed}
    end
  end

  @doc "Error raising version of `execute/1`"
  def execute!(req) do
    case execute(req) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  defp do_request(req) do
    url          = Request.get_url(req)
    query_params = Request.get_query_params(req)
    headers      = default_headers()
                   |> Map.merge(req.headers)
                   |> Enum.into([])
    http_options = default_options()
                   |> Map.merge(req.options)
                   |> Map.put(:params, query_params)
                   |> Enum.into([])
    body = Request.get_body(req)

    case HTTPoison.request(req.method, url, body, headers, http_options) do
      {:ok, _} = result -> result
      {:error, error} ->
        {:error, %RequestError{
          original_error: error,
          message: "Error completing HTTP request: #{error.reason}",
        }}
    end
  end

  defp parse_response(response) do
    with {:ok, doc} <- parse_document(response.body)
    do
      {:ok, %Response{
        status: response.status_code,
        doc: doc,
        headers: response.headers,
      }}
    else
      {:error, error} ->
        {:error, %RequestError{
          message: "Error Parsing JSON API Document",
          original_error: error,
          status: response.status_code,
        }}
    end
  end

  defp parse_document(""), do: {:ok, nil}
  defp parse_document(json), do: Parser.parse(json)

  defp default_options do
    %{
      timeout: timeout(),
      recv_timeout: timeout(),
    }
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
