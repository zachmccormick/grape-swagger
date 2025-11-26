# Configuration Reference

Complete reference for all grape-swagger configuration options.

## Basic Configuration

```ruby
add_swagger_documentation(
  # Required options
  api_version: '1.0.0',

  # Optional: Enable OpenAPI 3.1.0 (default: '2.0')
  openapi_version: '3.1.0'
)
```

## API Information

```ruby
add_swagger_documentation(
  info: {
    title: 'My API',
    description: 'API description in Markdown',
    terms_of_service: 'https://example.com/tos',
    contact: {
      name: 'API Support',
      email: 'support@example.com',
      url: 'https://example.com/support'
    },
    license: {
      name: 'MIT',
      url: 'https://opensource.org/licenses/MIT',
      identifier: 'MIT'  # OpenAPI 3.1.0 only (SPDX identifier)
    },
    summary: 'Brief API summary'  # OpenAPI 3.1.0 only
  }
)
```

## Server Configuration

### Swagger 2.0

```ruby
add_swagger_documentation(
  host: 'api.example.com',
  base_path: '/v1',
  schemes: ['https', 'http']
)
```

### OpenAPI 3.1.0

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  servers: [
    {
      url: 'https://api.example.com/v1',
      description: 'Production server'
    },
    {
      url: 'https://staging-api.example.com/v1',
      description: 'Staging server'
    }
  ]
)
```

### Server Variables

```ruby
servers: [
  {
    url: 'https://{environment}.example.com/{version}',
    variables: {
      environment: {
        default: 'api',
        enum: ['api', 'staging', 'dev']
      },
      version: {
        default: 'v1'
      }
    }
  }
]
```

## Security Configuration

### API Key

```ruby
security_definitions: {
  api_key: {
    type: 'apiKey',
    name: 'X-API-Key',
    in: 'header'
  }
}
```

### Bearer Token

```ruby
security_definitions: {
  bearer: {
    type: 'http',
    scheme: 'bearer',
    bearerFormat: 'JWT'
  }
}
```

### Basic Auth

```ruby
security_definitions: {
  basic: {
    type: 'http',
    scheme: 'basic'
  }
}
```

### OAuth2

```ruby
security_definitions: {
  oauth2: {
    type: 'oauth2',
    flows: {
      authorizationCode: {
        authorization_url: 'https://auth.example.com/authorize',
        token_url: 'https://auth.example.com/token',
        refresh_url: 'https://auth.example.com/refresh',
        scopes: {
          'read' => 'Read access',
          'write' => 'Write access'
        }
      },
      clientCredentials: {
        token_url: 'https://auth.example.com/token',
        scopes: { 'api' => 'API access' }
      },
      implicit: {
        authorization_url: 'https://auth.example.com/authorize',
        scopes: { 'read' => 'Read access' }
      },
      password: {
        token_url: 'https://auth.example.com/token',
        scopes: { 'user' => 'User access' }
      }
    }
  }
}
```

### OpenID Connect (OpenAPI 3.1.0 only)

```ruby
security_definitions: {
  openId: {
    type: 'openIdConnect',
    openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
  }
}
```

### Mutual TLS (OpenAPI 3.1.0 only)

```ruby
security_definitions: {
  mtls: {
    type: 'mutualTLS',
    description: 'Client certificate required'
  }
}
```

### Global Security

```ruby
# Apply security globally
security: [
  { api_key: [] },
  { oauth2: ['read'] }
]
```

## Webhooks (OpenAPI 3.1.0 only)

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    eventName: {
      post: {
        summary: 'Event description',
        request_body: {
          content: {
            'application/json' => {
              schema: { '$ref' => '#/components/schemas/Event' }
            }
          }
        },
        responses: {
          200 => { description: 'Success' }
        }
      }
    }
  }
)
```

## Documentation Paths

```ruby
add_swagger_documentation(
  mount_path: '/swagger_doc',    # Where to mount the documentation
  add_base_path: true,           # Add base_path to all paths
  add_version: true,             # Add version to paths
  hide_documentation_path: true  # Hide documentation path from spec
)
```

## Model Configuration

```ruby
add_swagger_documentation(
  models: [User, Post, Comment],  # Explicitly include models
  hide_format: true               # Hide format suffix from paths
)
```

## Tags

```ruby
add_swagger_documentation(
  tags: [
    { name: 'users', description: 'User operations' },
    { name: 'posts', description: 'Post operations' }
  ]
)
```

## External Documentation

```ruby
add_swagger_documentation(
  external_docs: {
    description: 'Find more info here',
    url: 'https://docs.example.com'
  }
)
```

## Request/Response Content Types

### Swagger 2.0

```ruby
add_swagger_documentation(
  consumes: ['application/json', 'application/xml'],
  produces: ['application/json', 'application/xml']
)
```

### OpenAPI 3.1.0

Content types are specified per-operation in requestBody and responses.

## Complete Example

```ruby
add_swagger_documentation(
  # Version
  openapi_version: '3.1.0',
  api_version: '1.0.0',

  # Info
  info: {
    title: 'My API',
    description: 'A comprehensive API',
    contact: {
      name: 'Support',
      email: 'support@example.com'
    },
    license: {
      name: 'MIT',
      identifier: 'MIT'
    }
  },

  # Servers
  servers: [
    { url: 'https://api.example.com/v1', description: 'Production' }
  ],

  # Security
  security_definitions: {
    bearer: {
      type: 'http',
      scheme: 'bearer',
      bearerFormat: 'JWT'
    }
  },
  security: [{ bearer: [] }],

  # Webhooks
  webhooks: {
    orderCreated: {
      post: {
        summary: 'Order created',
        request_body: {
          content: {
            'application/json' => {
              schema: { '$ref' => '#/components/schemas/Order' }
            }
          }
        },
        responses: { 200 => { description: 'OK' } }
      }
    }
  },

  # Tags
  tags: [
    { name: 'orders', description: 'Order management' }
  ],

  # Documentation
  mount_path: '/swagger_doc',
  hide_documentation_path: true
)
```
