defmodule JsonApiClient.Middleware.RunnerTest do
  use ExUnit.Case
  doctest JsonApiClient.Middleware.Runner, import: true

  import Mock
  alias JsonApiClient.Middleware.{Factory, Runner}

  test "calls Middleware in the correct order" do
    with_mock Factory, [], [middlewares: fn() ->
      [{FirstTestMiddleware, nil}, {LastTestMiddleware, nil}]
    end] do
      assert Runner.run("") == [:first, :last]
    end
  end

  test "does not call Middleware when `before` Middleware does not call next" do
    with_mock Factory, [], [middlewares: fn() ->
      [{StopTestMiddleware, nil}, {LastTestMiddleware, nil}]
    end] do
      assert Runner.run("") == [:stop]
    end
  end
end

defmodule StopTestMiddleware do
  @behaviour JsonApiClient.Middleware
  def call(_env, _next, _options) do
    [:stop]
  end
end

defmodule LastTestMiddleware do
  @behaviour JsonApiClient.Middleware
  def call(_env, _next, _options) do
    [:last]
  end
end

defmodule FirstTestMiddleware do
  @behaviour JsonApiClient.Middleware
  def call(env, next, _options) do
    [:first | next.(env)]
  end
end