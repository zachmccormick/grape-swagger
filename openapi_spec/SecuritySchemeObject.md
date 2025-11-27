# Security Scheme Object

Defines a security scheme that can be used by operations.

## Fixed Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `type` | string | Yes | :white_check_mark: | REQUIRED. Valid values: apiKey, http, mutualTLS, oauth2, openIdConnect |
| `description` | string | No | :white_check_mark: | A description for security scheme. CommonMark syntax MAY be used. |
| `name` | string | Conditional | :white_check_mark: | REQUIRED for apiKey. The name of the header, query or cookie parameter. |
| `in` | string | Conditional | :white_check_mark: | REQUIRED for apiKey. Location of the API key. Valid values: query, header, cookie |
| `scheme` | string | Conditional | :white_check_mark: | REQUIRED for http. The name of the HTTP Authorization scheme (e.g., basic, bearer) |
| `bearerFormat` | string | No | :white_check_mark: | Optional for http with bearer scheme. A hint to the client about bearer token format (e.g., JWT) |
| `flows` | [OAuth Flows Object](OAuthFlowsObject.md) | Conditional | :white_check_mark: | REQUIRED for oauth2. Configuration for the flow types supported |
| `openIdConnectUrl` | string | Conditional | :white_check_mark: | REQUIRED for openIdConnect. OpenID Connect URL to discover OAuth2 configuration values |

This object MAY be extended with Specification Extensions.

## Security Scheme Types

The `type` field determines which additional fields are required:

### Type: `apiKey`

API Key authentication. Requires:
- `name` (REQUIRED): Name of header, query or cookie parameter
- `in` (REQUIRED): Location of API key. Valid values: `query`, `header`, `cookie`

### Type: `http`

HTTP authentication as defined by RFC 7235. Requires:
- `scheme` (REQUIRED): Name of HTTP Authorization scheme (e.g., `basic`, `bearer`, `digest`)
- `bearerFormat` (optional): Hint about bearer token format when scheme is `bearer` (e.g., `JWT`)

Common HTTP schemes include: basic, bearer, digest, hoba, mutual, negotiate, oauth, scram-sha-1, scram-sha-256, vapid

### Type: `oauth2`

OAuth 2.0 authentication. Requires:
- `flows` (REQUIRED): OAuth Flows Object containing configuration for supported flows

Supported flows: implicit, password, clientCredentials, authorizationCode

### Type: `openIdConnect`

OpenID Connect Discovery authentication. Requires:
- `openIdConnectUrl` (REQUIRED): URL to discover OAuth2 configuration values (typically ends with `.well-known/openid-configuration`)

### Type: `mutualTLS`

Mutual TLS client certificate authentication (OpenAPI 3.1.0+).
- No additional fields required
- Indicates that client certificate authentication is used

## Examples

### API Key

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    api_key: {
      type: 'apiKey',
      name: 'X-API-Key',
      in: 'header',
      description: 'API key for authentication'
    }
  }
)
```

### HTTP Bearer (JWT)

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    bearer_auth: {
      type: 'http',
      scheme: 'bearer',
      bearerFormat: 'JWT',
      description: 'JWT token authentication'
    }
  }
)
```

### HTTP Basic

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    basic_auth: {
      type: 'http',
      scheme: 'basic',
      description: 'Basic HTTP authentication'
    }
  }
)
```

### OAuth 2.0

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    oauth2: {
      type: 'oauth2',
      description: 'OAuth 2.0 authentication',
      flows: {
        authorizationCode: {
          authorizationUrl: 'https://auth.example.com/authorize',
          tokenUrl: 'https://auth.example.com/token',
          refreshUrl: 'https://auth.example.com/refresh',
          scopes: {
            'read:users': 'Read user data',
            'write:users': 'Modify user data'
          }
        },
        clientCredentials: {
          tokenUrl: 'https://auth.example.com/token',
          scopes: {
            'api:full': 'Full API access'
          }
        }
      }
    }
  }
)
```

### OpenID Connect (3.1.0)

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    openid: {
      type: 'openIdConnect',
      openIdConnectUrl: 'https://auth.example.com/.well-known/openid-configuration',
      description: 'OpenID Connect authentication'
    }
  }
)
```

### Mutual TLS (3.1.0)

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    mutual_tls: {
      type: 'mutualTLS',
      description: 'Mutual TLS client certificate authentication'
    }
  }
)
```

## Output Example

```json
{
  "components": {
    "securitySchemes": {
      "api_key": {
        "type": "apiKey",
        "name": "X-API-Key",
        "in": "header",
        "description": "API key for authentication"
      },
      "bearer_auth": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT"
      },
      "oauth2": {
        "type": "oauth2",
        "flows": {
          "authorizationCode": {
            "authorizationUrl": "https://auth.example.com/authorize",
            "tokenUrl": "https://auth.example.com/token",
            "scopes": {
              "read:users": "Read user data",
              "write:users": "Modify user data"
            }
          }
        }
      }
    }
  }
}
```

## OpenAPI 3.1.0 Specification Compliance

All fields from the official OpenAPI 3.1.0 specification are documented and supported:

### Specification Reference
- Section: 4.8.27 Security Scheme Object
- Source: https://spec.openapis.org/oas/v3.1.0

### Field Coverage
- ✅ `type` - REQUIRED for all types
- ✅ `description` - Optional for all types
- ✅ `name` - REQUIRED for apiKey type
- ✅ `in` - REQUIRED for apiKey type (supports: query, header, cookie)
- ✅ `scheme` - REQUIRED for http type
- ✅ `bearerFormat` - Optional for http type
- ✅ `flows` - REQUIRED for oauth2 type
- ✅ `openIdConnectUrl` - REQUIRED for openIdConnect type
- ✅ mutualTLS type - No additional fields required

All fields are correctly implemented and pass validation.

## Tests

- `spec/grape-swagger/openapi/security_scheme_builder_spec.rb`
- `spec/grape-swagger/openapi/security_scheme_spec.rb`
- `spec/grape-swagger/openapi/security_integration_spec.rb`
- `spec/grape-swagger/openapi/security_tests_spec.rb`

## Implementation

- `lib/grape-swagger/openapi/security_scheme_builder.rb`
