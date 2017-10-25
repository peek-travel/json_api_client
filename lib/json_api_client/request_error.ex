defmodule JsonApiClient.RequestError do
  @moduledoc """
  A Fatal Error during an API request

  ## Fields
  * message - a short description of the error
  * original_error - The original error, if this error wraps one thrown by another library
  * status - The HTTP status code of the request, if any
  * attributes - Custom attributes.
  """

  defexception(
    message: nil,
    original_error: nil,
    status: nil,
    attributes: %{}
  )
end
