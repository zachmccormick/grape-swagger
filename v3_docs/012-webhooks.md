# PR 12: Webhooks

## Overview

WebhookBuilder creates the top-level `webhooks` object for OpenAPI 3.1.0 specifications. Webhooks describe API-provider-initiated HTTP requests (callbacks from server to client) and are a feature exclusive to OpenAPI 3.1.0.

## Key Components

### WebhookBuilder (`lib/grape-swagger/openapi/webhook_builder.rb`)

Class method `.build(webhook_definitions, version)` constructs the webhooks object:

- **build**: Entry point; iterates webhook definitions, returns nil for empty/nil input
- **build_webhook**: Wraps each webhook under its HTTP method (defaults to POST)
- **build_operation**: Builds the operation object with summary, description, requestBody, and responses
- **build_request_body**: Constructs requestBody with content type (defaults to `application/json`), required flag (defaults to true), and optional examples
- **build_responses**: Builds response objects keyed by status code with optional schemas
- **build_schema**: Handles both `$ref` references and inline schema definitions (including array items)

### Integration Points

- **SpecBuilderV3_1**: Calls `WebhookBuilder.build` and includes result as `webhooks` key in assembled spec (when present)
- Webhooks do not include `parameters` (no URL parameters for server-initiated requests)
- Supports `$ref` to `#/components/schemas/...` for both request and response schemas

## Configuration Example

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    user_signup: {
      summary: 'User signup event',
      description: 'Triggered when a new user registers',
      request: {
        description: 'User data payload',
        schema: { '$ref' => '#/components/schemas/User' }
      },
      responses: {
        200 => { description: 'Webhook received' }
      }
    },
    order_created: {
      summary: 'Order created',
      method: :put,
      request: {
        schema: {
          type: 'object',
          properties: {
            order_id: { type: 'integer' },
            total: { type: 'number' }
          }
        }
      },
      responses: {
        200 => { description: 'Success' },
        400 => { description: 'Invalid payload' }
      }
    }
  }
)
```

## Test Coverage

- `spec/grape-swagger/openapi/webhook_builder_spec.rb` - Unit tests for webhook definition structure, configuration API, schema references, and edge cases
- `spec/grape-swagger/openapi/webhook_integration_spec.rb` - Integration test verifying webhooks flow through SpecBuilderV3_1 into the assembled spec
