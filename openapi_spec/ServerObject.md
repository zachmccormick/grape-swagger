# Server Object

Represents a server target.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `url` | string | Yes | :white_check_mark: | Target host URL (may use variables) |
| `description` | string | No | :white_check_mark: | Server description |
| `variables` | Map[string, [Server Variable Object](ServerVariableObject.md)] | No | :white_check_mark: | URL template variables |

## Usage

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
    },
    {
      url: 'https://{environment}.example.com/{version}',
      description: 'Server with variables',
      variables: {
        environment: {
          default: 'api',
          enum: ['api', 'staging', 'sandbox'],
          description: 'Environment selector'
        },
        version: {
          default: 'v1',
          description: 'API version'
        }
      }
    }
  ]
)
```

## Output Example

```json
{
  "servers": [
    {
      "url": "https://api.example.com/v1",
      "description": "Production server"
    },
    {
      "url": "https://{environment}.example.com/{version}",
      "description": "Server with variables",
      "variables": {
        "environment": {
          "default": "api",
          "enum": ["api", "staging", "sandbox"],
          "description": "Environment selector"
        },
        "version": {
          "default": "v1",
          "description": "API version"
        }
      }
    }
  ]
}
```

## Tests

- `spec/grape-swagger/openapi/servers_builder_spec.rb`
- `spec/grape-swagger/openapi/servers_webhooks_spec.rb`

## Implementation

- `lib/grape-swagger/openapi/servers_builder.rb`

## Notes

- The `url` field supports RFC 6570 URI templates with variables
- Variables are substituted at runtime by API consumers
- At least one server should be provided for valid tooling support
