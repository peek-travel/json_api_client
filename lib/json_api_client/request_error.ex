defmodule JsonApiClient.RequestError do
  @moduledoc """
  A Fatal Error during an API request
  """

  defexception [:reason, :message, :original_error, :status]

  def exception(%__MODULE__{} = exception), do: exception
  def exception(params), do: struct(__MODULE__, params)
end
