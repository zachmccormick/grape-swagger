# Callback Object

A map of possible out-of-band callbacks related to the parent operation. Each value in the map is a Path Item Object that describes a set of requests that may be initiated by the API provider and the expected responses. The key value used to identify the path item object is an expression, evaluated at runtime, that identifies a URL to use for the callback operation.

## Patterned Fields

| Field Pattern | Type | Required | Supported | Notes |
|---------------|------|----------|-----------|-------|
| `{expression}` | [Path Item Object](PathItemObject.md) \| [Reference Object](ReferenceObject.md) | N/A | ✅ | Runtime expression evaluated at runtime to identify callback URL |

## Specification Extensions

This object MAY be extended with [Specification Extensions](SpecificationExtensions.md).

| Field Pattern | Type | Required | Supported | Notes |
|---------------|------|----------|-----------|-------|
| `^x-` | Any | No | ✅ | Custom vendor extensions |

## Status

✅ **Implemented in OpenAPI 3.1.0**

Callbacks are fully supported in grape-swagger for OpenAPI 3.1.0. They are not available in Swagger 2.0.

## Use Case

Callbacks describe webhook-style notifications that an API might send:

```json
{
  "paths": {
    "/webhooks": {
      "post": {
        "summary": "Register a webhook",
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "callbackUrl": {
                    "type": "string",
                    "format": "uri"
                  }
                }
              }
            }
          }
        },
        "callbacks": {
          "orderStatusUpdate": {
            "{$request.body#/callbackUrl}": {
              "post": {
                "summary": "Order status notification",
                "requestBody": {
                  "content": {
                    "application/json": {
                      "schema": {
                        "$ref": "#/components/schemas/OrderStatusEvent"
                      }
                    }
                  }
                },
                "responses": {
                  "200": {
                    "description": "Callback received successfully"
                  }
                }
              }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Webhook registered"
          }
        }
      }
    }
  }
}
```

## Runtime Expressions

Callback URLs use runtime expressions similar to Links:

| Expression | Description |
|-----------|-------------|
| `$url` | Full request URL |
| `$method` | HTTP method |
| `$statusCode` | Response status code |
| `$request.path.name` | Path parameter |
| `$request.query.name` | Query parameter |
| `$request.header.name` | Header value |
| `$request.body#/pointer` | Request body JSON pointer |
| `$response.body#/pointer` | Response body JSON pointer |
| `$response.header.name` | Response header value |

## Proposed Usage

```ruby
desc 'Register webhook',
     callbacks: {
       orderStatusUpdate: {
         '{$request.body#/callbackUrl}' => {
           post: {
             summary: 'Order status notification',
             requestBody: {
               content: {
                 'application/json' => {
                   schema: { '$ref' => '#/components/schemas/OrderStatusEvent' }
                 }
               }
             },
             responses: {
               '200' => { description: 'Callback received' }
             }
           }
         }
       }
     }
post '/webhooks' do
  # ...
end
```

## Implementation Details

### Supported Features

- ✅ Callback definitions in operations (via `callbacks:` option)
- ✅ Runtime expression URL support (all standard expressions)
- ✅ Path Item Objects describing callback requests
- ✅ Reference Objects for callback definitions
- ✅ Multiple callbacks per operation
- ✅ Request body schemas (inline and $ref)
- ✅ Response definitions
- ✅ Summary and description

### Limitations

- ❌ Reusable callbacks in `components/callbacks` (not yet implemented)
- ❌ Specification extensions (`x-` fields) in demo application

### Implementation Files

- **Builder**: `/lib/grape-swagger/openapi/callback_builder.rb`
- **Tests**: `/spec/grape-swagger/openapi/callback_builder_spec.rb`
- **Integration**: `/spec/grape-swagger/openapi/advanced_features_spec.rb`
