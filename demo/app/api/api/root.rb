# frozen_string_literal: true

require 'grape-swagger'
require 'grape-swagger-entity'

module API
  class Root < Grape::API
    format :json
    default_format :json

    # Mount API versions
    mount V1::PetsAPI
    mount V1::UsersAPI
    mount V1::OrdersAPI
    mount V1::FilesAPI
    mount V1::PaymentsAPI

    # Add Swagger documentation with OpenAPI 3.1.0
    add_swagger_documentation(
      # Version configuration
      openapi_version: '3.1.0',
      api_version: '1.0.0',

      # API Info with OpenAPI 3.1.0 enhancements
      info: {
        title: 'Demo API - OpenAPI 3.1.0 Features',
        description: <<~DESC,
          This API demonstrates the new OpenAPI 3.1.0 features supported by grape-swagger.

          ## Features Demonstrated

          - **Nullable Types**: Type arrays like `["string", "null"]` instead of `nullable: true`
          - **Binary Data**: contentEncoding and contentMediaType for file uploads
          - **Polymorphic Schemas**: oneOf, anyOf, allOf with discriminators
          - **Enhanced Security**: OAuth2 flows, OpenID Connect, Mutual TLS
          - **Webhooks**: Async event notifications for order lifecycle
          - **Server Variables**: Configurable server URLs

          ## Authentication

          This API supports multiple authentication methods:
          - API Key (header)
          - Bearer Token (JWT)
          - OAuth 2.0 (authorization code and client credentials)
          - OpenID Connect
        DESC
        contact: {
          name: 'API Support',
          email: 'api-support@example.com',
          url: 'https://example.com/support'
        },
        license: {
          name: 'MIT',
          identifier: 'MIT' # SPDX identifier (OpenAPI 3.1.0 feature)
        },
        summary: 'Demonstration of OpenAPI 3.1.0 features' # OpenAPI 3.1.0 feature
      },

      # Server configuration (OpenAPI 3.0+ style)
      servers: [
        {
          url: 'https://api.example.com/{version}',
          description: 'Production server',
          variables: {
            version: {
              default: 'v1',
              enum: %w[v1 v2],
              description: 'API version'
            }
          }
        },
        {
          url: 'https://staging-api.example.com/{version}',
          description: 'Staging server',
          variables: {
            version: {
              default: 'v1'
            }
          }
        },
        {
          url: 'http://localhost:3000',
          description: 'Local development'
        }
      ],

      # Security definitions with OpenAPI 3.1.0 schemes
      security_definitions: {
        api_key: {
          type: 'apiKey',
          name: 'X-API-Key',
          in: 'header',
          description: 'API key for service-to-service authentication'
        },
        bearer_auth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'JWT token authentication'
        },
        oauth2: {
          type: 'oauth2',
          description: 'OAuth 2.0 authentication with multiple flows',
          flows: {
            authorizationCode: {
              authorization_url: 'https://auth.example.com/oauth/authorize',
              token_url: 'https://auth.example.com/oauth/token',
              refresh_url: 'https://auth.example.com/oauth/refresh',
              scopes: {
                'read:pets' => 'Read pet information',
                'write:pets' => 'Create and update pets',
                'read:users' => 'Read user information',
                'write:users' => 'Update user profiles',
                'read:orders' => 'Read order information',
                'write:orders' => 'Create and manage orders',
                'manage:payments' => 'Manage payment methods',
                'upload:files' => 'Upload and manage files'
              }
            },
            clientCredentials: {
              token_url: 'https://auth.example.com/oauth/token',
              scopes: {
                'api:full' => 'Full API access for service accounts'
              }
            }
          }
        },
        openid_connect: {
          type: 'openIdConnect',
          openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration',
          description: 'OpenID Connect authentication (OpenAPI 3.1.0 feature)'
        },
        mutual_tls: {
          type: 'mutualTLS',
          description: 'Mutual TLS client certificate authentication (OpenAPI 3.1.0 feature)'
        }
      },

      # Default security requirements
      security: [
        { bearer_auth: [] },
        { api_key: [] }
      ],

      # Webhooks (OpenAPI 3.1.0 feature)
      webhooks: {
        orderCreated: {
          method: :post,
          summary: 'Order Created',
          description: 'Triggered when a new order is placed',
          request: {
            schema: { '$ref' => '#/components/schemas/Order' }
          },
          responses: {
            200 => { description: 'Webhook processed successfully' },
            400 => { description: 'Invalid webhook payload' }
          }
        },
        orderStatusChanged: {
          method: :post,
          summary: 'Order Status Changed',
          description: 'Triggered when an order status is updated',
          request: {
            schema: {
              type: 'object',
              properties: {
                order_id: { type: 'integer' },
                old_status: { type: 'string' },
                new_status: { type: 'string' },
                timestamp: { type: 'string', format: 'date-time' }
              },
              required: %w[order_id old_status new_status timestamp]
            }
          },
          responses: {
            200 => { description: 'Webhook processed' }
          }
        },
        paymentMethodAdded: {
          method: :post,
          summary: 'Payment Method Added',
          description: 'Triggered when a user adds a new payment method',
          request: {
            schema: { '$ref' => '#/components/schemas/PaymentMethod' }
          },
          responses: {
            200 => { description: 'Acknowledged' }
          }
        }
      },

      # Tags with descriptions
      tags: [
        { name: 'pets', description: 'Pet management with polymorphic types (Dog, Cat, Bird)' },
        { name: 'users', description: 'User management with nullable fields' },
        { name: 'orders', description: 'Order management with webhooks' },
        { name: 'files', description: 'File uploads with binary data handling' },
        { name: 'payments', description: 'Payment methods with oneOf polymorphism' }
      ],

      # External documentation
      external_docs: {
        description: 'Find more information about grape-swagger OpenAPI 3.1.0 support',
        url: 'https://github.com/ruby-grape/grape-swagger/blob/master/docs/OPENAPI_3_1_FEATURES.md'
      },

      # Documentation path configuration
      mount_path: '/swagger_doc',
      hide_documentation_path: true,
      hide_format: true
    )
  end
end
