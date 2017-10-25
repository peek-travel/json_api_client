# JsonApiClient
[![Hex.pm](https://img.shields.io/hexpm/v/json_api_client.svg)](https://hex.pm/packages/json_api_client)
[![Build Docs](https://img.shields.io/badge/hexdocs-release-blue.svg)](https://hexdocs.pm/json_api_client)

A JSON API Client for elixir.

**NOTICE**: This library is new and in active development. There could be
backwards incompatable changes as the design shakes out. YMMV, PRs welcome.

## Installation

This package can be installed
by adding `json_api_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:json_api_client, "~> 1.0.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/json_api_client](https://hexdocs.pm/json_api_client).

## Usage

```elixir
import JsonApiClient.Request

base_url = "http://example.com/"

# Fetch a resource by URL
{:ok, response} = fetch Request.new(base_url <> "/articles/123")

# build the request by composing helper functions
{:ok, response} = Request.new(base_url <> "/articles")
|> id("123")
|> fetch

# Fetch a list of resources
{:ok, response} = Request.new(base_url <> "/articles")
|> fields(articles: "title,topic", authors: "first-name,last-name,twitter")
|> include(:author)
|> sort(:id)
|> page(size: 10, number: 1)
|> filter(published: true)
|> params(custom1: 1, custom2: 2)
|> fetch

# Delete a resource
{:ok, response} = Request.new(base_url <> "/articles")
|> id("123")
|> delete

# Create a resource
new_article = %Resource{
  type: "articles",
  attributes: %{
    title: "JSON API paints my bikeshed!",
  }
}
{:ok, %{status: 201, doc: %{data: article}}} = Request.new(base_url <> "/articles")
|> resource(new_article)
|> create

# Update a resource
{:ok, %{status: 200, doc: %{data: updated_article}}} = Request.new(base_url <> "/articles")
|> resource(%Resource{article | attributes: %{title: "New Title}})
|> update

```

### Non-compliant servers

For the most part this library assumes that the server you're talking to implements the JSON:API spec correctly and treats deviations from that spec as exceptional (causing `JsonApiClient.execute/1` to return an `{:error, _}` tuple for example). One exception to this rule is the case where a server sends back an invalid body (HTML or some non-json string) along with a 4** or 5** status code. In those cases the body will simple be ignored. See the docs for `JsonApiClient.execute/1` for more details.

### Helpers for common URI structures

The JSON:API specification doesn't provide any guidance on [URI structure](http://jsonapi.org/faq/#position-uri-structure-custom-endpoints), but there is a common convention for REST apis to expose an enpoints with the following structure

```
# fetch a list of resources of a given type
GET /:type_name

# Create a resource of a given type
POST /:type_name

# Fetch/Update/Delete a resource by id
GET /:type_name/:id
PATCH /:type_name/:id
DELETE /:type_name/:id
```

When making requests to API endpoints that follow these conventions you can avoid having to build the full path yourself by adding `JsonApiClient.Resource` to the request.

```elixir
# GET base_url <> "/articles/123"
{:ok, response} = Request.new(base_url)
|> resource(%Resource{id: "123", type: "articles"})
|> fetch

# GET base_url <> "/articles"
{:ok, response} = Request.new(base_url)
|> resource(%Resource{type: "articles"})
|> fetch
```

You can also build paths to nested resources by passing a `Resource` to `path/2`

```elixir
# GET base_url <> "/articles/123/comments/456"
{:ok, response} = Request.new(base_url)
|> path(%Resource{id: "123", type: "articles"})
|> resource(%Resource{id: "456", type: "comments"})
|> fetch
```

If the API your making requests of follows a different URI pattern you can pass a string to `path/2` and it will be appended to the base url.

## Configuration

### user agent suffix

Every request made carries a special `User-Agent` header that looks like: `json_api_client/1.0.0/user_agent_suffix`. Each client is expected to set its `user_agent_suffix` via:

```elixir
config :json_api_client, user_agent_suffix: "yourSufix"
```

### timeout

This library allows its users to specify a timeout for all its service calls by using a `timeout` setting. By default, the timeout is set to 500msecs.

```elixir
config :json_api_client, timeout: 200
```

### middlewares

JsonApiClient is implemented using a middleware architecture. You can configure the middleware stack by setting `middlewares` to a list of `{Module, opts}` tuples where `Module` is a module that implements the `JsonApiClient.Middleware` behavior and `opts` is the options that will be passed as the last argument to the modules `call` function.

```elixir
config :json_api_client,
  middlewares: [
    {JsonApiClient.Middleware.DocumentParser, nil}
    {JsonApiClient.Middleware.HTTPClient, nil},
  ]
```

If you don't configure a value for `middlewares` you'll get a stack equivilent to the one configured in the preceding example. 

#### Included Middlewre

The following middleware ships with `JsonApiClient`

* `JsonApiClient.Middleware.Fuse`
* `JsonApiClient.Middleware.StatsTracker`
