# OAuth Flows Object

Allows configuration of the supported OAuth Flows.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `implicit` | [OAuth Flow Object](OAuthFlowObject.md) | No | :white_check_mark: | Implicit flow |
| `password` | [OAuth Flow Object](OAuthFlowObject.md) | No | :white_check_mark: | Password flow |
| `clientCredentials` | [OAuth Flow Object](OAuthFlowObject.md) | No | :white_check_mark: | Client credentials |
| `authorizationCode` | [OAuth Flow Object](OAuthFlowObject.md) | No | :white_check_mark: | Authorization code |

## Usage

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    oauth2: {
      type: 'oauth2',
      flows: {
        authorizationCode: {
          authorizationUrl: 'https://auth.example.com/authorize',
          tokenUrl: 'https://auth.example.com/token',
          refreshUrl: 'https://auth.example.com/refresh',
          scopes: {
            'read:users': 'Read user data',
            'write:users': 'Create and update users',
            'delete:users': 'Delete users'
          }
        },
        clientCredentials: {
          tokenUrl: 'https://auth.example.com/token',
          scopes: {
            'api:full': 'Full API access for service accounts'
          }
        },
        implicit: {
          authorizationUrl: 'https://auth.example.com/authorize',
          scopes: {
            'read:users': 'Read user data'
          }
        },
        password: {
          tokenUrl: 'https://auth.example.com/token',
          scopes: {
            'read:users': 'Read user data',
            'write:users': 'Modify user data'
          }
        }
      }
    }
  }
)
```

## Output Example

```json
{
  "components": {
    "securitySchemes": {
      "oauth2": {
        "type": "oauth2",
        "flows": {
          "authorizationCode": {
            "authorizationUrl": "https://auth.example.com/authorize",
            "tokenUrl": "https://auth.example.com/token",
            "refreshUrl": "https://auth.example.com/refresh",
            "scopes": {
              "read:users": "Read user data",
              "write:users": "Create and update users"
            }
          },
          "clientCredentials": {
            "tokenUrl": "https://auth.example.com/token",
            "scopes": {
              "api:full": "Full API access"
            }
          }
        }
      }
    }
  }
}
```

## Tests

- `spec/grape-swagger/openapi/security_scheme_builder_spec.rb`

## Implementation

- `lib/grape-swagger/openapi/security_scheme_builder.rb`
