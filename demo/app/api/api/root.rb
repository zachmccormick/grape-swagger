# frozen_string_literal: true

require 'grape-swagger'
require 'grape-swagger-entity'

module API
  # Helpers to generate $ref paths for OpenAPI components
  # These avoid hardcoding component paths and make refactoring easier

  # Usage: schema_ref(V1::Entities::Dog) => '#/components/schemas/V1_Entities_Dog'
  def self.schema_ref(klass)
    name = GrapeSwagger::DocMethods::DataType.parse_entity_name(klass)
    "#/components/schemas/#{name}"
  end

  # Usage: parameter_ref(:PageParam) => '#/components/parameters/PageParam'
  def self.parameter_ref(name)
    "#/components/parameters/#{name}"
  end

  # Usage: response_ref(:UnauthorizedError) => '#/components/responses/UnauthorizedError'
  def self.response_ref(name)
    "#/components/responses/#{name}"
  end

  # Usage: callback_ref(:EventNotification) => '#/components/callbacks/EventNotification'
  def self.callback_ref(name)
    "#/components/callbacks/#{name}"
  end

  # Usage: request_body_ref(:BulkUpdateBody) => '#/components/requestBodies/BulkUpdateBody'
  def self.request_body_ref(name)
    "#/components/requestBodies/#{name}"
  end

  # Usage: path_item_ref(:HealthCheck) => '#/components/pathItems/HealthCheck'
  def self.path_item_ref(name)
    "#/components/pathItems/#{name}"
  end

  # Usage: example_ref(:PetDogExample) => '#/components/examples/PetDogExample'
  def self.example_ref(name)
    "#/components/examples/#{name}"
  end

  # Usage: link_ref(:GetPetById) => '#/components/links/GetPetById'
  def self.link_ref(name)
    "#/components/links/#{name}"
  end

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

    # Advanced OpenAPI 3.1.0 feature demos (split into logical groups)
    mount V1::ParametersDemoAPI       # Cookie, deprecated, content field, examples, external docs
    mount V1::SchemaDemoAPI           # Validation keywords, discriminator, conditional, formats
    mount V1::CallbacksLinksDemoAPI   # Callbacks, links, runtime expressions
    mount V1::OperationsDemoAPI       # Servers, status codes, component refs, HTTP methods
    mount V1::RequestResponseDemoAPI  # Request body, encoding, response headers

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
          identifier: 'MIT', # SPDX identifier (OpenAPI 3.1.0 feature)
          url: 'https://opensource.org/licenses/MIT' # License URL
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
        # API Key in header (most common)
        api_key: {
          type: 'apiKey',
          name: 'X-API-Key',
          in: 'header',
          description: 'API key for service-to-service authentication'
        },
        # API Key in query parameter
        api_key_query: {
          type: 'apiKey',
          name: 'api_key',
          in: 'query',
          description: 'API key passed as query parameter (less secure, use for public APIs)'
        },
        # API Key in cookie
        api_key_cookie: {
          type: 'apiKey',
          name: 'session_token',
          in: 'cookie',
          description: 'Session token stored in cookie for browser-based authentication'
        },
        # HTTP Basic authentication
        basic_auth: {
          type: 'http',
          scheme: 'basic',
          description: 'HTTP Basic authentication (username:password base64 encoded)'
        },
        # HTTP Bearer (JWT)
        bearer_auth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'JWT token authentication'
        },
        # OAuth 2.0 with all four flows
        oauth2: {
          type: 'oauth2',
          description: 'OAuth 2.0 authentication with all four standard flows',
          flows: {
            # Implicit flow (legacy, for SPAs without backend)
            implicit: {
              authorization_url: 'https://auth.example.com/oauth/authorize',
              refresh_url: 'https://auth.example.com/oauth/refresh',
              scopes: {
                'read:profile' => 'Read user profile',
                'read:pets' => 'Read pet information'
              }
            },
            # Password flow (Resource Owner Password Credentials)
            password: {
              token_url: 'https://auth.example.com/oauth/token',
              refresh_url: 'https://auth.example.com/oauth/refresh',
              scopes: {
                'read:pets' => 'Read pet information',
                'write:pets' => 'Create and update pets',
                'read:users' => 'Read user information'
              }
            },
            # Authorization Code flow (recommended for web apps)
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
            # Client Credentials flow (for machine-to-machine)
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
        },
        # Webhook with GET method (for verification/health checks)
        webhookVerification: {
          method: :get,
          summary: 'Webhook Verification',
          description: 'GET request sent to verify webhook endpoint is accessible. Used for initial setup and periodic health checks.',
          parameters: [
            {
              name: 'challenge',
              in: 'query',
              required: true,
              schema: { type: 'string' },
              description: 'Challenge token to echo back for verification'
            }
          ],
          responses: {
            200 => {
              description: 'Verification successful - echo challenge token',
              content: {
                'text/plain' => {
                  schema: { type: 'string' },
                  example: 'challenge_token_12345'
                }
              }
            },
            401 => { description: 'Invalid or missing verification token' }
          }
        },
        # Webhook using $ref to a component schema
        petCreated: {
          method: :post,
          summary: 'Pet Created',
          description: 'Triggered when a new pet is registered. Uses $ref to reuse the Pet schema.',
          request: {
            schema: {
              '$ref' => API.schema_ref(V1::Entities::Pet)
            }
          },
          responses: {
            200 => { description: 'Pet creation acknowledged' },
            400 => { description: 'Invalid pet data' }
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
        { name: 'parameters', description: 'Parameter features: cookies, deprecated, content field, examples, external docs' },
        { name: 'schemas', description: 'Schema features: validation keywords, discriminator, conditional, formats' },
        { name: 'callbacks', description: 'Callback features: webhooks, runtime expressions, reusable callbacks' },
        { name: 'links', description: 'Link features: hypermedia links, operationRef, server override' },
        { name: 'operations', description: 'Operation features: servers, status codes, component refs, HTTP methods' },
        { name: 'requests', description: 'Request body features: descriptions, encoding, reusable bodies' },
        { name: 'responses', description: 'Response features: headers, examples, media types' }
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
          },
          FilterParam: {
            name: 'filter',
            in: 'query',
            description: 'Filter criteria for narrowing results',
            required: false,
            schema: { type: 'string' }
          }
        },
        # Reusable examples (demonstrating all Example Object fields)
        examples: {
          # Example with summary, description, and value
          PetDogExample: {
            summary: 'Golden Retriever dog',
            description: <<~DESC,
              A complete example of a trained Golden Retriever dog.
              This demonstrates a typical family pet with all fields populated.
            DESC
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
          # Example with summary, description, and value
          PetCatExample: {
            summary: 'Indoor tabby cat',
            description: 'An example of an indoor cat with hunting skills rated on a 1-10 scale.',
            value: {
              id: 2,
              name: 'Whiskers',
              pet_type: 'cat',
              color: 'orange',
              is_indoor: true,
              hunting_skill: 8
            }
          },
          # Example with all fields including description
          UserExample: {
            summary: 'Admin user profile',
            description: <<~DESC,
              A complete user profile example showing an admin user.
              Note: created_at is a readOnly field set by the server.
              Password fields are writeOnly and never included in responses.
            DESC
            value: {
              id: 1,
              username: 'johndoe',
              email: 'john.doe@example.com',
              roles: %w[user admin],
              created_at: '2024-01-15T10:30:00Z'
            }
          },
          # Example with externalValue (URL to external example file)
          OrderSchemaExample: {
            summary: 'Order from external schema',
            description: 'Order example loaded from an external JSON file. Use externalValue for large examples.',
            externalValue: 'https://example.com/schemas/order-example.json'
          },
          # Example with externalValue for API response
          ApiResponseExample: {
            summary: 'Large API response example',
            description: 'Complex API response example hosted externally to keep spec size manageable.',
            externalValue: 'https://api.example.com/docs/examples/large-response.json'
          },
          # Simple example with just summary and value
          PaginationExample: {
            summary: 'Standard pagination response',
            value: {
              page: 1,
              limit: 20,
              total: 150,
              has_more: true
            }
          },
          # Error response example with detailed description
          ValidationErrorExample: {
            summary: 'Field validation failure',
            description: <<~DESC,
              Example of a validation error response when required fields are missing
              or field values don't match expected formats/constraints.
              The details array contains specific field-level error messages.
            DESC
            value: {
              error: 'Validation failed',
              code: 'VALIDATION_ERROR',
              details: [
                { field: 'email', message: 'must be a valid email address' },
                { field: 'age', message: 'must be at least 18' }
              ]
            }
          }
        },
        # Reusable Request Bodies (OpenAPI 3.1.0)
        requestBodies: {
          PetBody: {
            description: 'Pet object to create or update. Supports polymorphic types (Dog, Cat, Bird).',
            required: true,
            content: {
              'application/json' => {
                schema: {
                  oneOf: [
                    { '$ref' => API.schema_ref(V1::Entities::Dog) },
                    { '$ref' => API.schema_ref(V1::Entities::Cat) },
                    { '$ref' => API.schema_ref(V1::Entities::Bird) }
                  ],
                  discriminator: {
                    propertyName: 'pet_type',
                    mapping: {
                      'dog' => API.schema_ref(V1::Entities::Dog),
                      'cat' => API.schema_ref(V1::Entities::Cat),
                      'bird' => API.schema_ref(V1::Entities::Bird)
                    }
                  }
                },
                examples: {
                  dog: {
                    summary: 'Create a dog',
                    value: { name: 'Rex', pet_type: 'dog', breed: 'German Shepherd', is_trained: true }
                  },
                  cat: {
                    summary: 'Create a cat',
                    value: { name: 'Whiskers', pet_type: 'cat', color: 'tabby', is_indoor: true }
                  }
                }
              }
            }
          },
          BulkUpdateBody: {
            description: 'Bulk update request for multiple resources at once.',
            required: true,
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    ids: {
                      type: 'array',
                      items: { type: 'integer' },
                      description: 'IDs of resources to update',
                      minItems: 1,
                      maxItems: 100
                    },
                    updates: {
                      type: 'object',
                      additionalProperties: true,
                      description: 'Fields to update on all selected resources'
                    }
                  },
                  required: %w[ids updates]
                },
                example: {
                  ids: [1, 2, 3, 4, 5],
                  updates: { status: 'archived', archived_at: '2024-01-15T12:00:00Z' }
                }
              }
            }
          },
          FileUploadBody: {
            description: 'File upload with metadata. Use multipart/form-data encoding.',
            required: true,
            content: {
              'multipart/form-data' => {
                schema: {
                  type: 'object',
                  properties: {
                    file: { type: 'string', format: 'binary', description: 'File to upload' },
                    filename: { type: 'string', description: 'Custom filename (optional)' },
                    description: { type: 'string', description: 'File description' },
                    tags: {
                      type: 'array',
                      items: { type: 'string' },
                      description: 'Tags for categorization'
                    }
                  },
                  required: ['file']
                },
                encoding: {
                  file: { contentType: 'application/octet-stream' },
                  tags: { style: 'form', explode: true }
                }
              }
            }
          }
        },
        # Reusable links
        links: {
          GetPetById: {
            operationId: 'getPet',
            parameters: { id: '$response.body#/id' },
            description: 'Get the pet by ID from the response'
          },
          GetUserById: {
            operationId: 'getUser',
            parameters: { id: '$response.body#/user_id' },
            description: 'Get the associated user'
          }
        },
        # Reusable path items
        pathItems: {
          HealthCheck: {
            summary: 'Standard health check endpoint',
            description: 'Returns service health status. Can be reused across multiple paths.',
            get: {
              summary: 'Health check',
              description: 'Returns 200 if the service is healthy',
              responses: {
                '200' => {
                  description: 'Service is healthy',
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'object',
                        properties: {
                          status: { type: 'string', enum: %w[healthy degraded unhealthy] },
                          timestamp: { type: 'string', format: 'date-time' }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        # Reusable callbacks (OpenAPI 3.1.0)
        # These can be referenced via $ref from operation callbacks
        callbacks: {
          # Standard event notification callback
          EventNotification: {
            '{$request.body#/callback_url}' => {
              post: {
                summary: 'Event notification callback',
                description: 'Called when an event occurs. The URL is taken from the callback_url field in the request body.',
                requestBody: {
                  required: true,
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'object',
                        properties: {
                          event_id: { type: 'string', format: 'uuid', description: 'Unique event identifier' },
                          event_type: { type: 'string', description: 'Type of event that occurred' },
                          timestamp: { type: 'string', format: 'date-time', description: 'When the event occurred' },
                          payload: { type: 'object', additionalProperties: true, description: 'Event-specific data' }
                        },
                        required: %w[event_id event_type timestamp]
                      }
                    }
                  }
                },
                responses: {
                  '200' => { description: 'Callback processed successfully' },
                  '410' => { description: 'Callback URL no longer valid - unsubscribe' }
                }
              }
            }
          },
          # Status update callback using query parameter
          StatusUpdate: {
            '{$request.query.webhook_url}' => {
              post: {
                summary: 'Status update callback',
                description: 'Called when status changes. URL from webhook_url query parameter.',
                requestBody: {
                  required: true,
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'object',
                        properties: {
                          resource_id: { type: 'integer', description: 'ID of the resource that changed' },
                          old_status: { type: 'string', description: 'Previous status' },
                          new_status: { type: 'string', description: 'New status' },
                          changed_at: { type: 'string', format: 'date-time' },
                          changed_by: { type: 'string', description: 'User or system that made the change' }
                        },
                        required: %w[resource_id old_status new_status changed_at]
                      }
                    }
                  }
                },
                responses: {
                  '200' => { description: 'Status update acknowledged' },
                  '202' => { description: 'Status update accepted for processing' }
                }
              }
            }
          },
          # Completion callback using header
          CompletionNotification: {
            '{$request.header.X-Callback-URL}' => {
              post: {
                summary: 'Completion notification',
                description: 'Called when a long-running operation completes. URL from X-Callback-URL header.',
                requestBody: {
                  required: true,
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'object',
                        properties: {
                          operation_id: { type: 'string', format: 'uuid',
                                          description: 'ID of the completed operation' },
                          status: { type: 'string', enum: %w[completed failed cancelled], description: 'Final status' },
                          result: { type: 'object', additionalProperties: true, description: 'Operation result data' },
                          error: {
                            type: 'object',
                            properties: {
                              code: { type: 'string' },
                              message: { type: 'string' }
                            },
                            description: 'Error details if status is failed'
                          },
                          duration_ms: { type: 'integer', description: 'How long the operation took in milliseconds' },
                          completed_at: { type: 'string', format: 'date-time' }
                        },
                        required: %w[operation_id status completed_at]
                      }
                    }
                  }
                },
                responses: {
                  '200' => { description: 'Completion acknowledged' },
                  '204' => { description: 'Completion acknowledged (no response body expected)' }
                }
              }
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
