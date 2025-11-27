# Contact Object

Contact information for the exposed API.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `name` | string | No | :white_check_mark: | Contact person/organization |
| `url` | string | No | :white_check_mark: | Contact URL |
| `email` | string | No | :white_check_mark: | Contact email |

## Usage

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  info: {
    title: 'My API',
    version: '1.0.0',
    contact: {
      name: 'API Support Team',
      url: 'https://example.com/support',
      email: 'api-support@example.com'
    }
  }
)
```

## Output Example

```json
{
  "info": {
    "contact": {
      "name": "API Support Team",
      "url": "https://example.com/support",
      "email": "api-support@example.com"
    }
  }
}
```

## Tests

- `spec/grape-swagger/openapi/info_builder_spec.rb`

## Implementation

- `lib/grape-swagger/openapi/info_builder.rb`
