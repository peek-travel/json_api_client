defmodule JsonApiClient.Parser.Schema do
  @moduledoc false

  def document_object do
    %{
      representation: JsonApiClient.Document,
      either_fields: ~w(data errors meta),
      fields: %{
        jsonapi: json_api_object(),
        data: allow_array(resource_object()),
        meta: meta_object(),
        included: array(resource_object()),
        errors: array(error_object()),
        links: links_object()
      }
    }
  end

  def resource_object do
    %{
      representation: JsonApiClient.Resource,
      required_fields: ~w(type id),
      fields: %{
        type: nil,
        id: nil,
        attributes: object_object(),
        relationships: Map.put(object_object(), :value_representation, relationships_object()),
        meta: meta_object(),
        links: links_object(),
      }
    }
  end

  def error_object do
    %{
      representation: JsonApiClient.Error,
      fields: %{
        id: nil,
        links: error_link_object(),
        status: nil,
        code: nil,
        title: nil,
        detail: nil,
        meta: meta_object(),
        source: error_source_object(),
      }
    }
  end

  def error_link_object  do
    %{
      representation: JsonApiClient.ErrorLink,
      fields: %{
        about: nil
      }
    }
  end

  def error_source_object  do
    %{
      representation: JsonApiClient.ErrorSource,
      either_fields: ~w(pointer parameter),
      fields: %{
        pointer: nil,
        parameter: nil
      }
    }
  end

  def json_api_object do
    %{
      representation: JsonApiClient.JsonApi,
      fields: %{
        meta: meta_object(),
        version: nil,
      }
    }
  end

  def links_object do
    %{
      representation: JsonApiClient.Links,
      fields: %{
        related: nil,
        self: nil,
        first: nil,
        prev: nil,
        next: nil,
        last: nil,
      }
    }
  end

  def relationships_object do
    %{
      representation: JsonApiClient.Relationship,
      either_fields: ~w(links data meta),
      fields: %{
        links: links_object(),
        meta: meta_object(),
        data: allow_array(resource_identifier_object())
      }
    }
  end

  def resource_identifier_object do
     %{
       representation: JsonApiClient.ResourceIdentifier,
       required_fields: ~w(type id),
       fields: %{
         type: nil,
         id: nil,
         meta: meta_object()
       }
     }
  end

  def object_object do
    %{
      representation: :object,
    }
  end

  def meta_object, do: object_object()

  defp allow_array(object), do: Map.put(object, :array, :allow)

  defp array(object), do: Map.put(object, :array, true)
end
