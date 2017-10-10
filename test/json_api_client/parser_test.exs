defmodule JsonApiClient.ParserTest do
  use ExUnit.Case
  doctest JsonApiClient.Parser, import: true

  alias JsonApiClient.{
    Document,
    Links,
    JsonApi,
    Resource,
    Error,
    ErrorLink,
    ErrorSource,
    ResourceIdentifier,
    Relationship,
    Parser,
  }

  describe "parse()" do
    test "returns an error when mandatory fileds are missing" do
      assert {:error, _} = Parser.parse(%{})
    end

    test "returns a Document" do
      assert {:ok, %Document{}} = Parser.parse(%{"meta" => %{}})
    end

    test "returns an error when a value is an array instead of simple value" do
      document_json = %{
        "meta" => %{},
        "jsonapi" => %{
          "version" => ["2.0"],
          "meta" => %{}
        }
      }
      assert {:error, _} = Parser.parse(document_json)
    end

    test "JSON API Object: is added when original data does not have jsonapi attribute" do
      assert {:ok, %Document{jsonapi: %JsonApi{version: "1.0", meta: %{}}}} = Parser.parse(%{"meta" => %{}})
    end

    test "JSON API Object: is added using fields from data jsonapi attribute" do
      document_json = %{
        "meta" => %{},
        "jsonapi" => %{
          "version" => "2.0",
          "meta" => %{}
        }
      }
      assert {:ok, %Document{jsonapi: %JsonApi{version: "2.0", meta: %{}}}} = Parser.parse(document_json)
    end

    test "JSON API Object: supports meta" do
      document_json = %{
        "meta" => %{},
        "jsonapi" => %{
          "version" => "2.0",
          "meta" => %{
            "copyright" => "Copyright 2015 Example Corp."
          }
        }
      }
      assert {:ok,
              %Document{
                jsonapi: %JsonApi{version: "2.0", meta: %{ "copyright" => "Copyright 2015 Example Corp."}}
              }} = Parser.parse(document_json)
    end

    test "JSON API Object: error is reported when meta is not an object" do
      document_json = %{
        "meta" => %{},
        "jsonapi" => %{
          "version" => "2.0",
          "meta" => "foo"
        }
      }
      assert {:error, "The field 'meta' must be an object."} = Parser.parse(document_json)
    end

    test "Meta Object: supports meta" do
      document_json = %{
        "meta" => %{
          "copyright" => "Copyright 2015 Example Corp."
        }
      }
      assert {:ok,
              %Document{ meta: %{ "copyright" => "Copyright 2015 Example Corp."}}} = Parser.parse(document_json)
    end

    test "Meta Object: error is reported when meta is not an object" do
      document_json = %{
        "meta" => "foo"
      }
      assert {:error, "The field 'meta' must be an object."} = Parser.parse(document_json)
    end

    test "Included Object: error is reported when included is not an array" do
      document_json = %{
        "meta" => %{},
        "included" => %{}
      }
      assert {:error, "The field 'included' must be an array."} = Parser.parse(document_json)
    end

    test "Included Object: when data does not contain required fields" do
      document_json = %{
        "meta" => %{},
        "included" => [%{
          "type" => "people"
        }]
      }
      assert {:error, "A 'included' MUST contain the following members: type, id"} = Parser.parse(document_json)
    end

    test "Included Object: when data contains required fields" do
      document_json = %{
        "meta" => %{},
        "included" => [%{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people"
        }]
      }
      assert {:ok, %Document{included: [%Resource{
        id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
        type: "people"}]
      }} = Parser.parse(document_json)
    end

    test "Errors Object: error is reported when errors is not an object" do
      document_json = %{
        "errors" => "foo"
      }
      assert {:error, "The field 'errors' must be an array."} = Parser.parse(document_json)
    end

    test "Errors Object: supports id, links, status, code, title, detail, meta and source" do
      document_json = %{
        "errors" => [%{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "links" => %{
            "about" => "any error"
          },
          "status" => "403",
          "code" => "200",
          "title" => "Error",
          "detail" => "Editing secret powers is not authorized on Sundays.",
          "meta" => %{
            "copyright" => "Copyright 2015 Example Corp."
          },
          "source" => %{
            "pointer" => "/data/attributes/title",
            "parameter" => "secret"
          }
        }]
      }
      assert {:ok, %Document{errors: [
        %Error{
          id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          links: %ErrorLink{about: "any error"},
          status: "403",
          code: "200",
          title: "Error",
          detail: "Editing secret powers is not authorized on Sundays.",
          meta: %{ "copyright" => "Copyright 2015 Example Corp."},
          source: %ErrorSource{ pointer: "/data/attributes/title", parameter: "secret"}
        }]
      }} = Parser.parse(document_json)
    end

    test "Resource Object: when data does not contain required fields" do
      document_json = %{
        "data" => %{
          "type" => "people"
        }
      }
      assert {:error, "A 'data' MUST contain the following members: type, id"} = Parser.parse(document_json)
    end

    test "Resource Object: when data contains required fields" do
      document_json = %{
        "data" => %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people"
        }
      }
      assert {:ok, %Document{data: %Resource{
        id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
        type: "people"}
      }} = Parser.parse(document_json)
    end

    test "Resource Object: when data contains attributes field" do
      document_json = %{
        "data" => %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people",
          "attributes" => %{
            "first_name" => "John",
            "last_name" => "Doe"
          }
        }
      }

      assert {:ok, %Document{data: %Resource{
        id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
        type: "people",
        attributes: %{
          "first_name" => "John",
          "last_name" => "Doe"
        }
      }}} = Parser.parse(document_json)
    end

    test "Resource Object: Relationships Object: when it is not an object" do
      document_json = %{
        "data" => %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people",
          "relationships" => "foo"
        }
      }

      assert {:error, "The field 'relationships' must be an object."} = Parser.parse(document_json)
    end

    test "Resource Object: Relationships Object: when mandatory fields are missing" do
      document_json = %{
        "data" => %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people",
          "relationships" => %{
            "author" => %{
            }
          }
        }
      }

      assert {:error, "A 'author' MUST contain at least one of the following members: links, data, meta"} = Parser.parse(document_json)
    end

    test "Resource Object: when data object is an array" do
      document_json = %{
        "data" => [
        %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people"
        },
        %{
          "id" => "10c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people"
        }]
      }
      assert {:ok, %Document{data: [
        %Resource{
          id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          type: "people"},
        %Resource{
          id: "10c4ca5a-beda-484e-bcd9-77b378aa48f3",
          type: "people"}
        ]
      }} = Parser.parse(document_json)
    end

    test "Resource Object: Relationships Object: supports links and meta" do
      document_json = %{
        "data" => %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people",
          "relationships" => %{
            "author" => %{
              "links" => %{
                "self" => "http://example.com/articles/1/relationships/author",
                "related" => "http://example.com/articles/1/author"
              },
              "meta" => %{
                 "copyright" => "Copyright 2015 Example Corp."
              }
            }
          }
        }
      }

      assert {:ok, %Document{data: %Resource{
        id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
        type: "people",
        relationships: %{
          "author" => %Relationship{
            links: %Links{
              self: "http://example.com/articles/1/relationships/author",
              related: "http://example.com/articles/1/author"
            },
            meta: %{
               "copyright" => "Copyright 2015 Example Corp."
            }
          }
        },
      }}} = Parser.parse(document_json)
    end

    test "Resource Object: Relationships Object: support Resource Identifier as a single object" do
      document_json = %{
        "data" => %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people",
          "relationships" => %{
            "author" => %{
              "data" => %{
                "type" => "people",
                "id" => "9",
                "meta" => %{"copyright" => "Copyright 2015 Example Corp."} }
            }
          }
        }
      }

      assert {:ok, %Document{data: %Resource{
        id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
        type: "people",
        relationships: %{
          "author" => %Relationship{
            data: %ResourceIdentifier{
               id: "9",
               type: "people",
               meta: %{
                 "copyright" => "Copyright 2015 Example Corp."
               }
            }
          }
        },
      }}} = Parser.parse(document_json)
    end

    test "Resource Object: Relationships Object: support Resource Identifier as an array" do
      document_json = %{
        "data" => %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people",
          "relationships" => %{
            "author" => %{
              "data" => [%{
                "type" => "people",
                "id" => "9",
                "meta" => %{"copyright" => "Copyright 2015 Example Corp."}
              }]
            }
          }
        }
      }

      assert {:ok, %Document{data: %Resource{
        id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
        type: "people",
        relationships: %{
          "author" => %Relationship{
            data: [%ResourceIdentifier{
               id: "9",
               type: "people",
               meta: %{
                 "copyright" => "Copyright 2015 Example Corp."
               }
            }]
          }
        },
      }}} = Parser.parse(document_json)
    end

    test "Resource Object: Relationships Object: support Resource Identifier as an empty array" do
      document_json = %{
        "data" => %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people",
          "relationships" => %{
            "author" => %{
              "data" => []
            }
          }
        }
      }

      assert {:ok, %Document{data: %Resource{
        id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
        type: "people",
        relationships: %{
          "author" => %Relationship{
            data: []
          }
        },
      }}} = Parser.parse(document_json)
    end

    test "Resource Object: Relationships Object: support Resource Identifier as nil" do
      document_json = %{
        "data" => %{
          "id" => "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type" => "people",
          "relationships" => %{
            "author" => %{
              "data" => nil
            }
          }
        }
      }

      assert {:ok, %Document{data: %Resource{
        id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
        type: "people",
        relationships: %{
          "author" => %Relationship{
            data: nil
          }
        },
      }}} = Parser.parse(document_json)
    end

    test "Links: supports self and related" do
      document_json = %{
        "meta" => %{},
        "links" => %{
          "self" => "http://example.com/articles?page[number]=3&page[size]=1",
          "related" => "http://example.com/articles?page[number]=1&page[size]=1"
        }
      }

      assert {:ok, %Document{
        links: %Links{
          self: "http://example.com/articles?page[number]=3&page[size]=1",
          related: "http://example.com/articles?page[number]=1&page[size]=1"
        }
      }} = Parser.parse(document_json)
    end

    test "Pagination Link: supports self, first, prev, next and last" do
      document_json = %{
        "data" => [],
        "links" => %{
          "self" => "http://example.com/articles?page[number]=3&page[size]=1",
          "first" => "http://example.com/articles?page[number]=1&page[size]=1",
          "prev" => "http://example.com/articles?page[number]=2&page[size]=1",
          "next" => "http://example.com/articles?page[number]=4&page[size]=1",
          "last" => "http://example.com/articles?page[number]=13&page[size]=1"
        }
      }

      assert {:ok, %Document{
        links: %Links{
          self: "http://example.com/articles?page[number]=3&page[size]=1",
          first: "http://example.com/articles?page[number]=1&page[size]=1",
          prev: "http://example.com/articles?page[number]=2&page[size]=1",
          next: "http://example.com/articles?page[number]=4&page[size]=1",
          last: "http://example.com/articles?page[number]=13&page[size]=1"
        }
      }} = Parser.parse(document_json)
    end

    test "Accepts a JSON String" do
      document_json_string = """
      {
        "data": {
          "id": "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
          "type": "people"
        }
      }
      """
      
      assert {:ok, %Document{data: %Resource{
        id: "91c4ca5a-beda-484e-bcd9-77b378aa48f3",
        type: "people"}
      }} = Parser.parse(document_json_string)
    end

    test "Returns an error when invalid json string given" do
      invalid_json_string = "This is not JSON"
      assert {:error, %Poison.SyntaxError{}} = Parser.parse(invalid_json_string)
    end

  end
end
