defmodule JsonApiClient.RequestError do
  @moduledoc """
  A Fatal Error during an API request
  """

  defstruct [:reason, :msg, :original_error, :status]
end
