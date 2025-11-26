# Migrating from Swagger 2.0 to OpenAPI 3.1.0

This guide covers migrating your grape-swagger configuration from Swagger 2.0 to OpenAPI 3.1.0.

## Quick Start

### Step 1: Enable OpenAPI 3.1.0

Add the `openapi_version` option to your configuration:

```ruby
# Before (Swagger 2.0 - default)
add_swagger_documentation(
  api_version: '1.0.0'
)

# After (OpenAPI 3.1.0)
add_swagger_documentation(
  openapi_version: '3.1.0',
  api_version: '1.0.0'
)
```

### Step 2: Update Configuration Options

Some configuration options have changed names or structure:

| Swagger 2.0 | OpenAPI 3.1.0 | Notes |
|-------------|---------------|-------|
| `host` | `servers` | Array of server objects |
| `basePath` | `servers[].url` | Included in server URL |
| `schemes` | `servers[].url` | Included in server URL |
| `consumes` | Per-operation `requestBody` | Content negotiation |
| `produces` | Per-operation `responses` | Content negotiation |

Example:

```ruby
# Before (Swagger 2.0)
add_swagger_documentation(
  host: 'api.example.com',
  base_path: '/v1',
  schemes: ['https']
)

# After (OpenAPI 3.1.0)
add_swagger_documentation(
  openapi_version: '3.1.0',
  servers: [
    {
      url: 'https://api.example.com/v1',
      description: 'Production'
    }
  ]
)
```

## Breaking Changes

### None for Swagger 2.0 Users

If you continue using Swagger 2.0 (the default), there are no breaking changes. Your existing configuration will work exactly as before.

### Schema Structure Changes (OpenAPI 3.1.0 only)

When using OpenAPI 3.1.0, some schema structures change automatically:

| Feature | Swagger 2.0 | OpenAPI 3.1.0 |
|---------|-------------|---------------|
| Nullable types | `x-nullable: true` | `type: ['string', 'null']` |
| Binary format | `type: file` | `contentEncoding: base64` |
| Integer format | `type: integer, format: int32` | `type: integer` |

These transformations happen automatically. No code changes required.

## New Features in OpenAPI 3.1.0

### Webhooks

Document async events your API publishes:

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    newOrder: {
      post: {
        summary: 'New order notification',
        request_body: {
          content: {
            'application/json' => {
              schema: { '$ref' => '#/components/schemas/Order' }
            }
          }
        },
        responses: {
          200 => { description: 'Webhook processed' }
        }
      }
    }
  }
)
```

### Callbacks

Document callback URLs for async operations:

```ruby
# Configured at the operation level (not yet integrated in add_swagger_documentation)
# Builders available: GrapeSwagger::OpenAPI::CallbackBuilder
```

### Links

Document operation chaining:

```ruby
# Configured at the response level (not yet integrated in add_swagger_documentation)
# Builders available: GrapeSwagger::OpenAPI::LinkBuilder
```

### Enhanced Security Schemes

OpenAPI 3.1.0 supports additional security scheme types:

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
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
        }
      }
    },
    openId: {
      type: 'openIdConnect',
      openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
    },
    mtls: {
      type: 'mutualTLS',
      description: 'Client certificate required'
    }
  }
)
```

### JSON Schema 2020-12 Features

OpenAPI 3.1.0 aligns with JSON Schema 2020-12:

- Conditional schemas (`if`/`then`/`else`)
- Dependent schemas (`dependentSchemas`, `dependentRequired`)
- Pattern properties
- Unevaluated properties

## Common Issues and Solutions

### Issue: Invalid schema references

**Problem**: `$ref` paths changed from `#/definitions/Model` to `#/components/schemas/Model`

**Solution**: grape-swagger handles this automatically. No action needed.

### Issue: File upload parameters

**Problem**: `type: file` is not valid in OpenAPI 3.1.0

**Solution**: grape-swagger automatically converts to:
```yaml
type: string
contentEncoding: base64
contentMediaType: application/octet-stream
```

### Issue: Nullable fields

**Problem**: `nullable: true` deprecated in favor of type arrays

**Solution**: grape-swagger automatically converts:
```yaml
# Swagger 2.0
type: string
nullable: true

# OpenAPI 3.1.0 (automatic)
type:
  - string
  - "null"
```

## Rollback Procedure

To rollback to Swagger 2.0, simply remove or change the `openapi_version` option:

```ruby
add_swagger_documentation(
  # Remove this line to use Swagger 2.0 (default)
  # openapi_version: '3.1.0',
  api_version: '1.0.0'
)
```

## Version Comparison

| Feature | Swagger 2.0 | OpenAPI 3.1.0 |
|---------|-------------|---------------|
| JSON Schema version | Draft 4 | 2020-12 |
| Webhooks | Not supported | Supported |
| Callbacks | Not supported | Supported |
| Links | Not supported | Supported |
| OpenID Connect | Not supported | Supported |
| Mutual TLS | Not supported | Supported |
| Type arrays for nullable | Not supported | Supported |
| contentEncoding | Not supported | Supported |
| Conditional schemas | Not supported | Supported |

## Need Help?

- [Open an issue](https://github.com/ruby-grape/grape-swagger/issues)
- [Read the documentation](https://github.com/ruby-grape/grape-swagger/blob/master/README.md)
