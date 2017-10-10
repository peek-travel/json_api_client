defmodule JsonApiClient.Response do
  @moduledoc """
  A response from JSON API request
  """

  defstruct [:status, :headers, :doc]
end
