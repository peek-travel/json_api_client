# Warning:
This library is currently in an alpha state and is not yet feature complete. It is not recommended for production environments. Stay tuned for a 1.0 release soon.

# JsonApiClient

A JSON API Client for elixir.

## Installation

This package can be installed
by adding `json_api_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_api_client, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/json_api_client](https://hexdocs.pm/json_api_client).

## Setup

### client name

Every request made carries a special `User-Agent` header that looks like: `ExApiClient/0.1.0/client_name`. Each client is expected to set its `client_name` via:

```
config :json_api_client, client_name: "yourAppName"
```

### timeout

This library allows its users to specify a timeout for all its service calls by using a `timeout` setting. By default, the timeout is set to 500msecs.

```
config :json_api_client, timeout: 200
```

## How to use

TODO: fill this in

