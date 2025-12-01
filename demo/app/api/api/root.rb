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
    mount V1::PublicAPI    # Public endpoints (no auth required)
    mount V1::LegacyAPI    # Deprecated endpoints
    mount V1::AdminAPI     # Admin endpoints (enhanced security)
    mount V1::AdvancedFeaturesAPI # Advanced OpenAPI 3.1.0 features demo

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
        termsOfService: 'https://example.com/terms-of-service', # OpenAPI standard field
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
      # Note: Using inline schemas since webhook $refs to entity schemas
      # require those entities to be registered in components first
      webhooks: {
        orderCreated: {
          method: :post,
          summary: 'Order Created',
          description: 'Triggered when a new order is placed',
          request: {
            schema: {
              type: 'object',
              properties: {
                id: { type: 'integer', description: 'Order ID' },
                order_number: { type: 'string', description: 'Order reference number' },
                status: { type: 'string', enum: %w[pending confirmed processing shipped delivered] },
                total_cents: { type: 'integer', description: 'Total in cents' },
                currency: { type: 'string', enum: %w[USD EUR GBP] },
                created_at: { type: 'string', format: 'date-time' }
              },
              required: %w[id order_number status total_cents currency created_at]
            }
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
                order_id: { type: 'integer', description: 'Order ID' },
                old_status: { type: 'string', description: 'Previous status' },
                new_status: { type: 'string', description: 'New status' },
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
            schema: {
              type: 'object',
              properties: {
                id: { type: 'integer', description: 'Payment method ID' },
                type: { type: 'string', enum: %w[credit_card bank_account digital_wallet] },
                is_default: { type: 'boolean' },
                created_at: { type: 'string', format: 'date-time' }
              },
              required: %w[id type is_default created_at]
            }
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
        { name: 'payments', description: 'Payment methods with oneOf polymorphism' },
        { name: 'public', description: 'Public endpoints requiring no authentication (security: [])' },
        { name: 'legacy', description: 'Deprecated endpoints - scheduled for removal (deprecated: true)' },
        { name: 'admin', description: 'Admin endpoints with enhanced security (AND/OR security combinations)' },
        { name: 'advanced', description: 'Advanced OpenAPI 3.1.0 features: cookies, deprecated params, callbacks, links, externalDocs' }
      ],

      # External documentation
      external_docs: {
        description: 'Find more information about grape-swagger OpenAPI 3.1.0 support',
        url: 'https://github.com/ruby-grape/grape-swagger/blob/master/docs/OPENAPI_3_1_FEATURES.md'
      },

      # Reusable components for OpenAPI 3.1.0
      components: {
        # Reusable responses
        responses: {
          UnauthorizedError: {
            description: 'Authentication credentials are missing or invalid',
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    error: { type: 'string', example: 'Invalid or missing authentication token' },
                    code: { type: 'string', example: 'UNAUTHORIZED' }
                  }
                }
              }
            }
          },
          ForbiddenError: {
            description: 'The authenticated user does not have permission for this action',
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    error: { type: 'string', example: 'Insufficient permissions' },
                    code: { type: 'string', example: 'FORBIDDEN' }
                  }
                }
              }
            }
          },
          NotFoundError: {
            description: 'The requested resource was not found',
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    error: { type: 'string', example: 'Resource not found' },
                    code: { type: 'string', example: 'NOT_FOUND' }
                  }
                }
              }
            }
          },
          ValidationError: {
            description: 'The request body or parameters failed validation',
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    error: { type: 'string', example: 'Validation failed' },
                    code: { type: 'string', example: 'VALIDATION_ERROR' },
                    details: {
                      type: 'array',
                      items: {
                        type: 'object',
                        properties: {
                          field: { type: 'string' },
                          message: { type: 'string' }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          InternalServerError: {
            description: 'An unexpected error occurred on the server',
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    error: { type: 'string', example: 'Internal server error' },
                    code: { type: 'string', example: 'INTERNAL_ERROR' },
                    request_id: { type: 'string', description: 'Request ID for support reference' }
                  }
                }
              }
            }
          }
        },
        # Reusable parameters
        parameters: {
          PageParam: {
            name: 'page',
            in: 'query',
            description: 'Page number for pagination (1-based)',
            required: false,
            schema: { type: 'integer', minimum: 1, default: 1 }
          },
          LimitParam: {
            name: 'limit',
            in: 'query',
            description: 'Maximum number of items to return',
            required: false,
            schema: { type: 'integer', minimum: 1, maximum: 100, default: 20 }
          },
          OffsetParam: {
            name: 'offset',
            in: 'query',
            description: 'Number of items to skip',
            required: false,
            schema: { type: 'integer', minimum: 0, default: 0 }
          },
          SortParam: {
            name: 'sort',
            in: 'query',
            description: 'Sort order for results',
            required: false,
            schema: { type: 'string', enum: %w[asc desc], default: 'desc' }
          },
          IdPathParam: {
            name: 'id',
            in: 'path',
            description: 'Unique resource identifier',
            required: true,
            schema: { type: 'integer', format: 'int64' }
          }
        },
        # Reusable examples
        examples: {
          PetDogExample: {
            summary: 'Example dog',
            value: {
              id: 1,
              name: 'Buddy',
              pet_type: 'dog',
              breed: 'Golden Retriever',
              is_trained: true,
              birth_date: '2020-03-15',
              weight: 32.5
            }
          },
          PetCatExample: {
            summary: 'Example cat',
            value: {
              id: 2,
              name: 'Whiskers',
              pet_type: 'cat',
              color: 'orange',
              is_indoor: true,
              hunting_skill: 8
            }
          },
          UserExample: {
            summary: 'Example user',
            value: {
              id: 1,
              username: 'johndoe',
              email: 'john.doe@example.com',
              roles: %w[user admin],
              created_at: '2024-01-15T10:30:00Z'
            }
          }
        }
      },

      # Documentation path configuration
      mount_path: '/swagger_doc',
      hide_documentation_path: true,
      hide_format: true,

      # Register all models for polymorphic schema generation
      # This ensures Dog, Cat, Bird, CreditCard, etc. get their own allOf schemas
      models: [
        V1::Entities::Pet,
        V1::Entities::Dog,
        V1::Entities::Cat,
        V1::Entities::Bird,
        V1::Entities::PaymentMethod,
        V1::Entities::CreditCard,
        V1::Entities::BankAccount,
        V1::Entities::DigitalWallet
      ]
    )
  end
end
