# OAuth Flow Object

Configuration details for a supported OAuth Flow.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `authorizationUrl` | string | Conditional | :white_check_mark: | For implicit/authorizationCode |
| `tokenUrl` | string | Conditional | :white_check_mark: | For password/clientCredentials/authorizationCode |
| `refreshUrl` | string | No | :white_check_mark: | Token refresh URL |
| `scopes` | Map[string, string] | Yes | :white_check_mark: | Scope name → description |

## Required Fields by Flow Type

| Flow Type | authorizationUrl | tokenUrl |
|-----------|------------------|----------|
| implicit | Required | N/A |
| password | N/A | Required |
| clientCredentials | N/A | Required |
| authorizationCode | Required | Required |

## Usage

### Authorization Code Flow

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
            'write:users': 'Modify user data',
            'admin': 'Full admin access'
          }
        }
      }
    }
  }
)
```

### Client Credentials Flow

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    oauth2_client: {
      type: 'oauth2',
      flows: {
        clientCredentials: {
          tokenUrl: 'https://auth.example.com/token',
          scopes: {
            'api:read': 'Read API resources',
            'api:write': 'Write API resources'
          }
        }
      }
    }
  }
)
```

### Implicit Flow (Legacy)

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    oauth2_implicit: {
      type: 'oauth2',
      flows: {
        implicit: {
          authorizationUrl: 'https://auth.example.com/authorize',
          scopes: {
            'read:users': 'Read user data'
          }
        }
      }
    }
  }
)
```

### Password Flow (Legacy)

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    oauth2_password: {
      type: 'oauth2',
      flows: {
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
  "authorizationCode": {
    "authorizationUrl": "https://auth.example.com/authorize",
    "tokenUrl": "https://auth.example.com/token",
    "refreshUrl": "https://auth.example.com/refresh",
    "scopes": {
      "read:users": "Read user data",
      "write:users": "Modify user data"
    }
  }
}
```

## Tests

- `spec/grape-swagger/openapi/security_scheme_builder_spec.rb`

## Implementation

- `lib/grape-swagger/openapi/security_scheme_builder.rb`
