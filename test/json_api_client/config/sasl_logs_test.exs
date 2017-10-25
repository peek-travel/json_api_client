defmodule JsonApiClient.Config.SASLLogsTest do
  use ExUnit.Case
  doctest JsonApiClient.Config.SASLLogs, import: true

  alias JsonApiClient.Config.SASLLogs

  test "suppresses SASL reports" do
    assert SASLLogs.suppress(1, :info, :report, {:progress, :foo}) == :skip
  end

  test "does not suppress anything but SASL reports" do
    assert SASLLogs.suppress(1, :info, :format, "foo") == :none
  end
end