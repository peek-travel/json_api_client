defmodule JsonApiClient.Middleware.DefaultRequestConfig do
  @behaviour JsonApiClient.Middleware
  @moduledoc """
  Adds default headers and options to the request.
  """

  @timeout Application.get_env(:json_api_client, :timeout, 500)
  @version Mix.Project.config[:version]
  @package_name JsonApiClient.Mixfile.project[:app]

  alias Mix.Project
  alias JsonApiClient.Request

  def call(%Request{} = request, next, _) do
    headers      = Map.merge(default_headers(), request.headers)
    http_options = Map.merge(default_options(), request.options)

    next.(Map.merge(request, %{headers: headers, options: http_options}))
  end

  defp default_headers do
    %{
      "Accept"       => "application/vnd.api+json",
      "Content-Type" => "application/vnd.api+json",
      "User-Agent"   => user_agent()              ,
    }
  end

  defp default_options do
    %{
      timeout: timeout(),
      recv_timeout: timeout(),
    }
  end

  defp user_agent do
    [@package_name, @version, user_agent_suffix()]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("/")
  end

  defp user_agent_suffix do
    Application.get_env(:json_api_client, :user_agent_suffix, Project.config[:app])
  end

  defp timeout do
    @timeout
  end
end
