# Webhook Examples for OpenAPI 3.1.0

This document provides examples of how to use the webhook feature in grape-swagger for OpenAPI 3.1.0.

## Basic Webhook Definition

```ruby
class MyAPI < Grape::API
  format :json

  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'My API',
      version: '1.0.0'
    },
    webhooks: {
      user_signup: {
        summary: 'User signup event',
        description: 'Triggered when a new user registers',
        request: {
          description: 'User data payload',
          schema: { '$ref' => '#/components/schemas/User' }
        },
        responses: {
          200 => { description: 'Webhook received' },
          400 => { description: 'Invalid payload' }
        }
      }
    }
  )
end
```

## Multiple Webhooks

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    user_signup: {
      summary: 'User signup event',
      request: {
        schema: { '$ref' => '#/components/schemas/User' }
      },
      responses: {
        200 => { description: 'Success' }
      }
    },
    order_created: {
      summary: 'Order created event',
      request: {
        schema: { '$ref' => '#/components/schemas/Order' }
      },
      responses: {
        200 => { description: 'Success' }
      }
    },
    payment_received: {
      summary: 'Payment received event',
      request: {
        schema: { '$ref' => '#/components/schemas/Payment' }
      },
      responses: {
        200 => { description: 'Success' }
      }
    }
  }
)
```

## Webhook with Inline Schema

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    user_updated: {
      summary: 'User profile updated',
      description: 'Sent when a user updates their profile',
      request: {
        description: 'Updated user data',
        schema: {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            email: { type: 'string', format: 'email' },
            name: { type: 'string' },
            updated_at: { type: 'string', format: 'date-time' }
          },
          required: ['id', 'email']
        }
      },
      responses: {
        200 => { description: 'Webhook processed' }
      }
    }
  }
)
```

## Webhook with Examples

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    order_shipped: {
      summary: 'Order shipped notification',
      request: {
        schema: { '$ref' => '#/components/schemas/Order' },
        examples: {
          default: {
            summary: 'Standard order shipment',
            value: {
              order_id: 12345,
              tracking_number: 'TRACK123456',
              carrier: 'UPS',
              shipped_at: '2025-01-15T10:30:00Z'
            }
          },
          express: {
            summary: 'Express delivery shipment',
            value: {
              order_id: 67890,
              tracking_number: 'EXPRESS789',
              carrier: 'FedEx',
              shipped_at: '2025-01-15T11:00:00Z',
              express: true
            }
          }
        }
      },
      responses: {
        200 => { description: 'Notification acknowledged' }
      }
    }
  }
)
```

## Webhook with Array Schema (Batch Events)

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    batch_events: {
      summary: 'Batch event notifications',
      description: 'Multiple events sent in a single webhook call',
      request: {
        schema: {
          type: 'array',
          items: {
            '$ref' => '#/components/schemas/Event'
          }
        }
      },
      responses: {
        200 => { description: 'All events processed' },
        207 => { description: 'Partial success' }
      }
    }
  }
)
```

## Webhook with Custom HTTP Method

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    health_check: {
      method: :get,  # Use GET instead of default POST
      summary: 'Health check webhook',
      description: 'Periodic health check callback',
      request: {
        schema: { type: 'object' }
      },
      responses: {
        200 => { description: 'Healthy' },
        503 => { description: 'Unhealthy' }
      }
    }
  }
)
```

## Webhook with Response Schema

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    sync_request: {
      summary: 'Synchronous data sync request',
      request: {
        schema: { '$ref' => '#/components/schemas/SyncRequest' }
      },
      responses: {
        200 => {
          description: 'Sync successful',
          schema: {
            '$ref' => '#/components/schemas/SyncResponse'
          }
        },
        409 => {
          description: 'Conflict',
          schema: {
            type: 'object',
            properties: {
              error: { type: 'string' },
              conflicts: {
                type: 'array',
                items: { type: 'string' }
              }
            }
          }
        }
      }
    }
  }
)
```

## Complete Example with Components

```ruby
class MyAPI < Grape::API
  format :json

  # Define entities
  class UserEntity < Grape::Entity
    expose :id
    expose :email
    expose :name
    expose :created_at
  end

  class OrderEntity < Grape::Entity
    expose :order_id
    expose :user_id
    expose :total
    expose :status
    expose :created_at
  end

  # API endpoints
  resource :users do
    desc 'Create a user'
    params do
      requires :email, type: String
      requires :name, type: String
    end
    post do
      # User creation logic
    end
  end

  # Documentation with webhooks
  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'My API with Webhooks',
      version: '1.0.0',
      description: 'API that sends webhook notifications for events'
    },
    webhooks: {
      user_created: {
        summary: 'New user webhook',
        description: 'Sent when a new user is created',
        request: {
          schema: { '$ref' => '#/components/schemas/UserEntity' }
        },
        responses: {
          200 => { description: 'Webhook received' }
        }
      },
      order_placed: {
        summary: 'Order placed webhook',
        description: 'Sent when a new order is placed',
        request: {
          schema: { '$ref' => '#/components/schemas/OrderEntity' }
        },
        responses: {
          200 => { description: 'Webhook received' }
        }
      }
    }
  )
end
```

## Generated OpenAPI Specification

The above examples will generate an OpenAPI 3.1.0 specification with a `webhooks` section:

```yaml
openapi: 3.1.0
info:
  title: My API
  version: 1.0.0
paths:
  # Your API paths here
webhooks:
  user_signup:
    post:
      summary: User signup event
      description: Triggered when a new user registers
      requestBody:
        description: User data payload
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/User'
      responses:
        '200':
          description: Webhook received
        '400':
          description: Invalid payload
```

## Notes

- Webhooks are a top-level object in OpenAPI 3.1.0
- Each webhook is identified by a unique name (key)
- Webhooks default to POST operations but can use other HTTP methods
- Webhooks do NOT have parameters (query, path, etc.)
- The `request` configuration maps to `requestBody` in the spec
- Schema references work the same as in regular endpoints
- Examples can be provided for webhook payloads
- Response schemas can be defined for webhook responses
