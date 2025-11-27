# Tag Object

Adds metadata to a single tag that is used by the Operation Object.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `name` | string | Yes | :white_check_mark: | Tag name |
| `description` | string | No | :white_check_mark: | Tag description |
| `externalDocs` | [External Documentation Object](ExternalDocumentationObject.md) | No | :x: | External documentation |

## Usage

### Global Tags Definition

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  tags: [
    { name: 'users', description: 'User management operations' },
    { name: 'orders', description: 'Order processing and management' },
    { name: 'products', description: 'Product catalog operations' }
  ]
)
```

### Operation-Level Tags

```ruby
desc 'Get all users',
     tags: ['users', 'admin']
get '/users' do
  # ...
end
```

### Automatic Tag from Resource

```ruby
# Tags are automatically generated from the API class name
class UsersAPI < Grape::API
  # All endpoints here will be tagged with 'users'
  get '/' do
    # Tagged as 'users'
  end
end
```

## Output Example

```json
{
  "tags": [
    {
      "name": "users",
      "description": "User management operations"
    },
    {
      "name": "orders",
      "description": "Order processing and management"
    }
  ],
  "paths": {
    "/users": {
      "get": {
        "tags": ["users", "admin"]
      }
    }
  }
}
```

## Tests

- `spec/swagger_v2/api_swagger_v2_spec.rb`
- `spec/swagger_v2/api_swagger_v2_global_configuration_spec.rb`

## Implementation

- `lib/grape-swagger/endpoint.rb`
- `lib/grape-swagger.rb` (configuration)

## TODO

- [ ] Add externalDocs support for tags
