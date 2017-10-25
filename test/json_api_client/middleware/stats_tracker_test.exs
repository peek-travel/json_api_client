defmodule TestMiddleware do
  def call(_,_,_), do: nil
end

defmodule JsonApiClient.Middleware.StatsTrackerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  doctest JsonApiClient.Middleware.StatsTracker, import: true
  
  alias JsonApiClient.Middleware.StatsTracker
  import JsonApiClient.Middleware.StatsTracker
  alias JsonApiClient.Response

  @request %{url: "http://example.com"}

  test "adds timer stats to the response" do
    response = %Response{doc: "the doc"}

    assert {:ok, response} = StatsTracker.call(
      @request,
      fn _ -> {:ok, response} end,
      name: :some_name
    )

    assert %{
      doc: "the doc",
      attributes: %{stats: %{timers: [some_name: ms]}}
    } = response

    assert is_number ms
  end
    
  test "logs stats if `log` specified in options" do
    log = capture_log fn -> 
      assert {:ok, _} = StatsTracker.call(
        @request,
        fn _ -> {:ok, %Response{}} end,
        name: :some_name,
        log: :info
      )
    end

    assert log =~ "[info]"
    assert log =~ ~r/some_name_ms=\d+(\.\d+)?/
    assert log =~ ~r/total_ms=\d+(\.\d+)?/
  end

  describe "stats_from_response()" do
    test "calculates times from timers" do
      response = %Response{
        attributes: %{
          stats: %{ 
            timers: [
              test_middleware1: 30,
              test_middleware2: 20,
              test_middleware3: 15,
            ]
          }
        }
      }

      assert [
        total_ms: 30,
        test_middleware1_ms: 10,
        test_middleware2_ms: 5,
        test_middleware3_ms: 15,
      ] == stats_from_response(response)
    end
  end  

  describe "stats_from_request()" do
    test "includes the url" do
      assert [
        url: "http://example.com",
      ] = stats_from_request(%{url: "http://example.com"})
    end
  end
end
