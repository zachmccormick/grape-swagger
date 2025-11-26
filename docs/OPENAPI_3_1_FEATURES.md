# OpenAPI 3.1.0 Features Guide

This guide covers the new features available when using OpenAPI 3.1.0 with grape-swagger.

## Enabling OpenAPI 3.1.0

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0'
)
```

## Webhooks

Webhooks document async events that your API publishes to subscriber endpoints.

### Basic Usage

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    newOrder: {
      post: {
        summary: 'New order notification',
        description: 'Called when a new order is placed',
        request_body: {
          content: {
            'application/json' => {
              schema: { '$ref' => '#/components/schemas/Order' }
            }
          }
        },
        responses: {
          200 => { description: 'Webhook processed successfully' },
          400 => { description: 'Invalid payload' }
        }
      }
    }
  }
)
```

### Generated Output

```yaml
webhooks:
  newOrder:
    post:
      summary: New order notification
      description: Called when a new order is placed
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Order'
      responses:
        '200':
          description: Webhook processed successfully
        '400':
          description: Invalid payload
```

### Multiple Webhooks

```ruby
webhooks: {
  orderCreated: {
    post: {
      summary: 'Order created',
      request_body: { ... }
    }
  },
  orderUpdated: {
    post: {
      summary: 'Order updated',
      request_body: { ... }
    }
  },
  orderCancelled: {
    post: {
      summary: 'Order cancelled',
      request_body: { ... }
    }
  }
}
```

## Security Schemes

OpenAPI 3.1.0 supports enhanced security schemes.

### OAuth2 with Multiple Flows

```ruby
security_definitions: {
  oauth2: {
    type: 'oauth2',
    description: 'OAuth2 authentication',
    flows: {
      authorizationCode: {
        authorization_url: 'https://auth.example.com/authorize',
        token_url: 'https://auth.example.com/token',
        refresh_url: 'https://auth.example.com/refresh',
        scopes: {
          'read' => 'Read access to resources',
          'write' => 'Write access to resources',
          'admin' => 'Administrative access'
        }
      },
      clientCredentials: {
        token_url: 'https://auth.example.com/token',
        scopes: {
          'api' => 'API access'
        }
      }
    }
  }
}
```

### OpenID Connect

```ruby
security_definitions: {
  openId: {
    type: 'openIdConnect',
    description: 'OpenID Connect authentication',
    openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
  }
}
```

### Mutual TLS

```ruby
security_definitions: {
  mtls: {
    type: 'mutualTLS',
    description: 'Client certificate authentication required'
  }
}
```

### Combining Security Schemes

```ruby
# AND combination (both required)
security: [
  { apiKey: [], oauth2: ['read'] }
]

# OR combination (either works)
security: [
  { apiKey: [] },
  { oauth2: ['read'] }
]
```

## JSON Schema 2020-12 Features

### Nullable Types

Nullable types are represented as type arrays:

```ruby
# Input
{ type: 'string', nullable: true }

# Output (OpenAPI 3.1.0)
{ type: ['string', 'null'] }
```

### Binary Data

Binary data uses contentEncoding:

```ruby
# Input
{ type: 'string', format: 'binary' }

# Output (OpenAPI 3.1.0)
{
  type: 'string',
  contentEncoding: 'base64',
  contentMediaType: 'application/octet-stream'
}
```

### Conditional Schemas

Use if/then/else for conditional validation:

```ruby
# Using ConditionalSchemaBuilder
GrapeSwagger::OpenAPI::ConditionalSchemaBuilder.build(
  schema,
  version,
  if_schema: { properties: { type: { const: 'credit_card' } } },
  then_schema: { required: ['card_number'] },
  else_schema: { required: ['bank_account'] }
)
```

Generated output:

```yaml
type: object
if:
  properties:
    type:
      const: credit_card
then:
  required:
    - card_number
else:
  required:
    - bank_account
```

### Dependent Schemas

Use dependentSchemas for property dependencies:

```ruby
# Using DependentSchemaHandler
GrapeSwagger::OpenAPI::DependentSchemaHandler.apply(
  schema,
  version,
  dependent_schemas: {
    credit_card: {
      properties: {
        card_number: { type: 'string' }
      },
      required: ['card_number']
    }
  }
)
```

### Pattern Properties

Define schemas for dynamic property names:

```ruby
# Using AdditionalPropertiesHandler
GrapeSwagger::OpenAPI::AdditionalPropertiesHandler.apply(
  schema,
  version,
  pattern_properties: {
    '^x-' => { type: 'string' }
  },
  additional_properties: false
)
```

## Discriminator and Polymorphism

### Discriminator with Mapping

```ruby
# Using DiscriminatorBuilder
discriminator = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(
  {
    property_name: 'petType',
    mapping: {
      'dog' => 'Dog',
      'cat' => 'Cat',
      'bird' => 'Bird'
    }
  },
  version
)
```

Generated output:

```yaml
discriminator:
  propertyName: petType
  mapping:
    dog: '#/components/schemas/Dog'
    cat: '#/components/schemas/Cat'
    bird: '#/components/schemas/Bird'
```

### oneOf Schemas

Use oneOf for exclusive alternatives:

```ruby
# Using PolymorphicSchemaBuilder
schema = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_one_of(
  ['SuccessResponse', 'ErrorResponse'],
  { property_name: 'status' },
  version
)
```

Generated output:

```yaml
oneOf:
  - $ref: '#/components/schemas/SuccessResponse'
  - $ref: '#/components/schemas/ErrorResponse'
discriminator:
  propertyName: status
```

### anyOf Schemas

Use anyOf for flexible matching:

```ruby
schema = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_any_of(
  ['BasicInfo', 'ExtendedInfo'],
  nil,
  version
)
```

### allOf for Inheritance

```ruby
schema = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_all_of(
  'Pet',
  { type: 'object', properties: { breed: { type: 'string' } } },
  version
)
```

Generated output:

```yaml
allOf:
  - $ref: '#/components/schemas/Pet'
  - type: object
    properties:
      breed:
        type: string
```

## Server Configuration

### Multiple Servers

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  servers: [
    {
      url: 'https://api.example.com/v1',
      description: 'Production'
    },
    {
      url: 'https://staging-api.example.com/v1',
      description: 'Staging'
    },
    {
      url: 'http://localhost:3000/v1',
      description: 'Development'
    }
  ]
)
```

### Server Variables

```ruby
servers: [
  {
    url: 'https://{environment}.example.com/{version}',
    description: 'Configurable server',
    variables: {
      environment: {
        default: 'api',
        enum: ['api', 'staging', 'dev'],
        description: 'Environment'
      },
      version: {
        default: 'v1',
        description: 'API version'
      }
    }
  }
]
```

## Info Object Enhancements

### License with SPDX Identifier

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  info: {
    title: 'My API',
    version: '1.0.0',
    license: {
      name: 'MIT',
      identifier: 'MIT'  # SPDX identifier (OpenAPI 3.1.0 only)
    }
  }
)
```

### Summary Field

```ruby
info: {
  title: 'My API',
  summary: 'A brief summary of the API',  # OpenAPI 3.1.0 only
  description: 'A longer description...',
  version: '1.0.0'
}
```

## Performance Optimization

### Caching

grape-swagger provides caching utilities for better performance:

```ruby
# Using ReferenceCache for schema lookups
cache = GrapeSwagger::OpenAPI::ReferenceCache.new(max_size: 1000)
schema = cache.fetch('User') { build_user_schema }
```

### Lazy Loading

Components can be built on-demand:

```ruby
# Using LazyComponentBuilder
builder = GrapeSwagger::OpenAPI::LazyComponentBuilder.new(version)
builder.register('User') { { type: 'object', properties: { ... } } }
# Schema not built yet...
schema = builder.resolve('User')  # Now it's built
```

### Benchmarking

Measure generation performance:

```ruby
# Using BenchmarkSuite
result = GrapeSwagger::OpenAPI::BenchmarkSuite.run_benchmark(iterations: 10) do
  api.swagger_doc
end
puts GrapeSwagger::OpenAPI::BenchmarkSuite.format_results(result)
```

## Swagger 2.0 Compatibility

All OpenAPI 3.1.0 features gracefully degrade for Swagger 2.0:

- Webhooks: Not generated (Swagger 2.0 doesn't support them)
- Callbacks: Not generated
- Links: Not generated
- OpenID Connect: Not generated
- Mutual TLS: Not generated
- Type arrays: Uses `x-nullable` extension
- contentEncoding: Uses `format: binary`

No errors are raised. The specification is simply generated without the unsupported features.
