defmodule JsonApiClient.Response do
  @moduledoc """
  A response from JSON API request

  ## Fields
  * status - The HTTP Status code from the response
  * headers - The HTTP Headers as a list of tuples `[{header, value}, ...]`
  * doc - A `JsonApiClient.Document` if one was present in the response or nil
  * attributes - Custom attributes.
  """

  defstruct(
    status: nil,
    headers: nil,
    doc: nil,
    attributes: %{}
  )
end
