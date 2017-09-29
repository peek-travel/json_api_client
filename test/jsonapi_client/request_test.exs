defmodule JsonApiClient.RequestTest do
  use ExUnit.Case
  doctest JsonApiClient.Request, import: true
  alias JsonApiClient.Request

  test "get a resource", context do
    assert 1 == 1
  end
end
