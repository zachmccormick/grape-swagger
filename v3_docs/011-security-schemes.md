# PR 11: Security Scheme Builder

## Overview

SecuritySchemeBuilder transforms security scheme configurations between OpenAPI 3.1.0 and Swagger 2.0 formats. It supports OAuth2 (all 4 flows), OpenID Connect, mutual TLS, HTTP bearer/basic, and API key schemes with backward compatibility.

## Key Components

### SecuritySchemeBuilder (`lib/grape-swagger/openapi/security_scheme_builder.rb`)

Class method `.build(security_config, version)` routes to version-specific builders:

- **OpenAPI 3.1.0**: Full support for all scheme types
  - OAuth2 with authorizationCode, clientCredentials, implicit, password flows
  - OpenID Connect with `openIdConnectUrl`
  - Mutual TLS (`mutualTLS` type)
  - HTTP bearer/basic with `scheme` and `bearerFormat`
  - API key with `name` and `in`

- **Swagger 2.0**: Backward compatible output
  - OAuth2 flows converted (authorizationCode -> accessCode, clientCredentials -> application)
  - Only first flow used (Swagger 2.0 limitation)
  - OpenID Connect and mutual TLS filtered out (unsupported in 2.0)
  - HTTP schemes converted to `type: basic`
  - API key passed through

### Integration Points

- **ComponentsBuilder**: Uses SecuritySchemeBuilder to transform `securitySchemes` within components
- **Endpoint**: Security per-operation via `desc security: [...]` option
- **SpecBuilderV3_1**: Top-level `security` array for global security requirements

## Configuration Example

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
          scopes: { 'read' => 'Read access' }
        }
      }
    },
    api_key: {
      type: 'apiKey',
      name: 'X-API-Key',
      in: 'header'
    }
  },
  security: [{ oauth2: ['read'] }]
)
```

## Test Coverage

- `spec/grape-swagger/openapi/security_scheme_builder_spec.rb` - Unit tests for all scheme types and version compatibility
- `spec/grape-swagger/openapi/security_integration_spec.rb` - Full integration tests with Grape API endpoints
