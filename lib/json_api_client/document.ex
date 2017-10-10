defmodule JsonApiClient.Links do
  @moduledoc """
  JSON API JSON Links
  http://jsonapi.org/format/#document-links
  """

  defstruct(
    self: nil,
    related: nil,
    self: nil,
    first: nil,
    prev: nil,
    next: nil,
    last: nil
  )
end

defmodule JsonApiClient.ErrorLink do
  @moduledoc """
  JSON API JSON Error Object
  http://jsonapi.org/format/#errors
  """

  defstruct about: nil
end

defmodule JsonApiClient.ErrorSource do
  @moduledoc """
  JSON API JSON Error Object
  http://jsonapi.org/format/#errors
  """

  defstruct pointer: nil, parameter: nil
end

defmodule JsonApiClient.Error do
  @moduledoc """
  JSON API JSON Error Object
  http://jsonapi.org/format/#errors
  """

  defstruct(
    id: nil,
    links: nil,
    status: nil,
    code: nil,
    title: nil,
    detail: nil,
    meta: nil,
    source: nil,
  )
end

defmodule JsonApiClient.ResourceIdentifier do
  @moduledoc """
  JSON API Resource Identifier Object
  http://jsonapi.org/format/#document-resource-identifier-objects
  """

  defstruct id: nil, type: nil, meta: nil
end

defmodule JsonApiClient.Relationship do
  @moduledoc """
  JSON API Relationships Object
  http://jsonapi.org/format/#document-resource-object-relationships
  """

  defstruct links: nil, meta: nil, data: nil
end

defmodule JsonApiClient.Resource do
  @moduledoc """
  JSON API Resource Object
  http://jsonapi.org/format/#document-resource-objects
  """

  defstruct(
    id:            nil,
    type:          nil,
    attributes:    nil,
    links:         nil,
    relationships: nil,
    meta:          nil,
  )
end

defmodule JsonApiClient.JsonApi do
  @moduledoc """
  JSON API JSON API Object
  http://jsonapi.org/format/#document-jsonapi-object
  """

  defstruct version: "1.0", meta: %{}
end

defmodule JsonApiClient.Document do
  @moduledoc """
  JSON API Document Object
  http://jsonapi.org/format/#document-structure
  """

  defstruct(
    jsonapi: nil,
    data: nil,
    links: nil,
    meta: nil,
    included: nil,
    errors: nil
  )
end
