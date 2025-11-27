# Webhooks (OpenAPI 3.1.0)

Webhooks allow describing API callbacks that may be initiated by the API provider (rather than the consumer). Webhooks are defined at the top level of the OpenAPI document.

## Official Specification

According to the OpenAPI 3.1.0 specification, webhooks represent "incoming webhooks that MAY be received as part of this API and that the API consumer MAY choose to implement."

The official specification describes webhooks as describing "requests initiated by the API provider and the expected responses" and uses the Path Item Object structure.

Webhooks are:
- A top-level field in the OpenAPI Object (alongside `paths` and `components`)
- Optional at the root level
- A Map of string keys to Path Item Objects (or Reference Objects)
- Related to callbacks but describe requests initiated "other than by an API call, for example by an out of band registration"
- Described using the same Path Item Object structure as regular paths
- Each webhook is identified by a unique string serving as a reference key

## Structure

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `webhooks` | Map[string, Path Item Object \| Reference Object] | No | :white_check_mark: | Top-level webhook definitions |

### Webhook Entry Structure

Each webhook is defined as:
- **Key**: Unique string identifier for the webhook
- **Value**: Path Item Object (or Reference Object) describing the request the API provider may initiate and the expected responses

## Status

:white_check_mark: **Fully Implemented** (OpenAPI 3.1.0)

Webhooks are fully supported by grape-swagger as of Phase 4 (Sprint 11).

## Difference from Callbacks

| Feature | Callbacks | Webhooks |
|---------|-----------|----------|
| Defined in | Operation | Top-level |
| Triggered by | Specific operation | API-wide events |
| URL source | Request parameter | Pre-registered |
| Use case | Operation-specific notifications | General event notifications |

## OpenAPI Specification Example

```json
{
  "openapi": "3.1.0",
  "info": {
    "title": "Webhook Example"
  },
  "webhooks": {
    "orderStatusChange": {
      "post": {
        "summary": "Order status webhook",
        "description": "Sent when an order status changes",
        "operationId": "orderStatusWebhook",
        "requestBody": {
          "required": true,
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
            "description": "Webhook processed successfully"
          }
        }
      }
    },
    "newUser": {
      "post": {
        "summary": "New user webhook",
        "description": "Sent when a new user registers",
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/UserCreatedEvent"
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Acknowledged"
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "OrderStatusEvent": {
        "type": "object",
        "properties": {
          "order_id": { "type": "string" },
          "status": { "type": "string" },
          "timestamp": { "type": "string", "format": "date-time" }
        }
      },
      "UserCreatedEvent": {
        "type": "object",
        "properties": {
          "user_id": { "type": "string" },
          "email": { "type": "string", "format": "email" },
          "created_at": { "type": "string", "format": "date-time" }
        }
      }
    }
  }
}
```

## Proposed Usage

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    orderStatusChange: {
      post: {
        summary: 'Order status webhook',
        description: 'Sent when an order status changes',
        requestBody: {
          required: true,
          content: {
            'application/json' => {
              schema: OrderStatusEventEntity
            }
          }
        },
        responses: {
          '200' => { description: 'Webhook processed' }
        }
      }
    }
  }
)
```

## Key Characteristics

### What Makes Webhooks Optional

The specification explicitly states that webhooks "MAY be received" and that "the API consumer MAY choose to implement" them. This means:
- Webhooks are not required for the API to function
- API consumers can optionally register to receive webhook notifications
- The API provider initiates these requests to consumers who have opted in
- Registration typically happens "out of band" (e.g., via a dashboard, separate API call, or configuration)

### Similarities to Paths
- Both use Path Item Objects for defining operations
- Support the same HTTP methods (GET, POST, PUT, DELETE, PATCH, etc.)
- Use the same operation definitions and response structures
- Can reference schemas in components
- Can include Reference Objects instead of inline Path Item Objects

### Differences from Paths
- **Paths**: Define endpoints your API exposes (requests made TO your API)
- **Webhooks**: Define callbacks your API makes (requests made BY your API to consumer URLs)
- Webhooks don't have actual URL paths - the consumer provides the URL when registering
- Webhooks represent outbound notifications, not inbound requests

### Differences from Callbacks
Callbacks and webhooks are closely related but differ in their triggering mechanism and scope:

| Feature | Callbacks | Webhooks |
|---------|-----------|----------|
| Defined in | Operation | Top-level |
| Triggered by | Specific operation | API-wide events |
| URL source | Request parameter | Pre-registered |
| Use case | Operation-specific notifications | General event notifications |

Callbacks describe requests initiated "by an API call" (e.g., a callback URL passed in the request), while webhooks describe requests initiated "other than by an API call, for example by an out of band registration" (e.g., configured in a dashboard).

## Implementation Details

### What We Support

grape-swagger fully implements the Webhooks specification:

- Top-level `webhooks` field in OpenAPI 3.1.0 documents
- Multiple named webhook definitions
- Path Item Object structure for each webhook
- POST operations (default) and other HTTP methods (GET, PUT, etc.)
- Request body with schema definitions
- Response definitions with status codes
- Both inline schemas and $ref references
- Summary and description fields
- Examples for request payloads
- Array schemas for batch events

### Implementation Files

- `/Users/zach.mccormick/Braze/grape-swagger/lib/grape-swagger/openapi/webhook_builder.rb` - Main webhook builder
- `/Users/zach.mccormick/Braze/grape-swagger/spec/grape-swagger/openapi/webhook_builder_spec.rb` - Comprehensive tests
- `/Users/zach.mccormick/Braze/grape-swagger/spec/grape-swagger/openapi/servers_webhooks_spec.rb` - Integration tests

### Not Yet Supported

The following features from the Path Item Object specification are not yet implemented for webhooks:
- Reference Objects for webhook definitions (using `$ref` instead of inline definitions)
- Path Item `$ref`, `summary`, and `description` fields
- Operation-level `servers` array
- Path-level `parameters` array
- Other HTTP methods like `trace`, `options`, `head` (though these are rarely used for webhooks)
