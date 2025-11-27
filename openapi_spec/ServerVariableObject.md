# Server Variable Object

An object representing a Server Variable for URL template substitution.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `enum` | [string] | No | :white_check_mark: | Enumeration of allowed values |
| `default` | string | Yes | :white_check_mark: | Default value for substitution |
| `description` | string | No | :white_check_mark: | Variable description |

## Usage

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  servers: [
    {
      url: 'https://{region}.api.example.com/{version}',
      description: 'Regional API server',
      variables: {
        region: {
          default: 'us-east',
          enum: ['us-east', 'us-west', 'eu-west', 'ap-south'],
          description: 'Geographic region for the API'
        },
        version: {
          default: 'v1',
          enum: ['v1', 'v2'],
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
      "url": "https://{region}.api.example.com/{version}",
      "variables": {
        "region": {
          "default": "us-east",
          "enum": ["us-east", "us-west", "eu-west", "ap-south"],
          "description": "Geographic region for the API"
        },
        "version": {
          "default": "v1",
          "enum": ["v1", "v2"],
          "description": "API version"
        }
      }
    }
  ]
}
```

## Tests

- `spec/grape-swagger/openapi/servers_builder_spec.rb`

## Implementation

- `lib/grape-swagger/openapi/servers_builder.rb`

## Notes

- If `enum` is provided, the `default` value MUST be one of the enum values
- Variables are replaced in the URL template at runtime
- Common use cases: API versioning, regional endpoints, environment selection
