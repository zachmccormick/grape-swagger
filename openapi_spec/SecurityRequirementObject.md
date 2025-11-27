# Security Requirement Object

Lists the required security schemes to execute an operation.

## Structure

Each name MUST correspond to a security scheme declared in the Security Schemes under Components. If the security scheme is of type `oauth2` or `openIdConnect`, the value is a list of scope names required. For other types, the array MUST be empty.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `{name}` | [string] | N/A | :white_check_mark: | Security scheme name → required scopes |

## Usage

### Global Security (All Operations)

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    api_key: {
      type: 'apiKey',
      name: 'X-API-Key',
      in: 'header'
    }
  },
  security: [{ api_key: [] }]
)
```

### Operation-Level Security

```ruby
desc 'Get protected resource',
     security: [{ bearer_auth: [] }]
get '/protected' do
  # ...
end
```

### OAuth2 with Scopes

```ruby
desc 'Update user',
     security: [{ oauth2: ['write:users'] }]
put '/users/:id' do
  # ...
end
```

### Multiple Schemes (AND)

```ruby
# Both api_key AND bearer_auth required
desc 'Highly secured endpoint',
     security: [{ api_key: [], bearer_auth: [] }]
```

### Alternative Schemes (OR)

```ruby
# Either api_key OR bearer_auth accepted
desc 'Flexible auth endpoint',
     security: [{ api_key: [] }, { bearer_auth: [] }]
```

### No Security (Override Global)

```ruby
desc 'Public endpoint',
     security: []
get '/public' do
  # ...
end
```

## Output Example

```json
{
  "paths": {
    "/users/{id}": {
      "put": {
        "security": [
          { "oauth2": ["write:users"] }
        ]
      }
    },
    "/admin": {
      "get": {
        "security": [
          { "api_key": [], "bearer_auth": [] }
        ]
      }
    }
  },
  "security": [
    { "api_key": [] }
  ]
}
```

## Tests

- `spec/grape-swagger/openapi/security_tests_spec.rb`
- `spec/grape-swagger/openapi/security_integration_spec.rb`

## Implementation

- `lib/grape-swagger/endpoint.rb`
- `lib/grape-swagger/openapi/security_scheme_builder.rb`
