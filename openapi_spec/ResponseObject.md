# Response Object

Describes a single response from an API Operation.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `description` | string | Yes | :white_check_mark: | From `message:` in failure or desc |
| `headers` | Map[string, [Header Object](HeaderObject.md) \| Reference Object] | No | :white_check_mark: | Response headers |
| `content` | Map[string, [Media Type Object](MediaTypeObject.md)] | No | :white_check_mark: | Response body |
| `links` | Map[string, [Link Object](LinkObject.md) \| Reference Object] | No | :white_check_mark: | Operation links |

## Usage

### Basic Response

```ruby
desc 'Get a user' do
  success model: Entities::User
end
get ':id' do
  present user, with: Entities::User
end
```

### Response with Example

```ruby
desc 'Get a user' do
  success model: Entities::User, examples: {
    'application/json' => { id: 1, name: 'John', email: 'john@example.com' }
  }
end
```

### Response with Headers

```ruby
desc 'Get users' do
  success model: Entities::User, headers: {
    'X-Total-Count' => {
      description: 'Total number of items',
      schema: { type: 'integer' }
    },
    'X-Page' => {
      description: 'Current page',
      schema: { type: 'integer' }
    }
  }
end
```

### Response with Links

```ruby
desc 'Get user' do
  success model: Entities::User, links: {
    'GetUserOrders' => {
      operationId: 'getUserOrders',
      parameters: { userId: '$response.body#/id' }
    }
  }
end
```

## Output Example

```json
{
  "200": {
    "description": "Get a user",
    "headers": {
      "X-Total-Count": {
        "description": "Total number of items",
        "schema": { "type": "integer" }
      }
    },
    "content": {
      "application/json": {
        "schema": {
          "$ref": "#/components/schemas/User"
        },
        "example": {
          "id": 1,
          "name": "John",
          "email": "john@example.com"
        }
      }
    },
    "links": {
      "GetUserOrders": {
        "operationId": "getUserOrders",
        "parameters": {
          "userId": "$response.body#/id"
        }
      }
    }
  }
}
```

## Failure Responses

```ruby
desc 'Create user' do
  failure [
    { code: 400, message: 'Validation failed', model: Entities::ValidationError },
    { code: 401, message: 'Unauthorized' },
    { code: 409, message: 'Email already exists', model: Entities::ConflictError,
      examples: { 'application/json' => { error: 'Email already registered' } } }
  ]
end
```

## Tests

- `spec/swagger_v2/api_swagger_v2_response_spec.rb`
- `spec/swagger_v2/api_swagger_v2_response_with_examples_spec.rb`
- `spec/swagger_v2/api_swagger_v2_response_with_headers_spec.rb`
- `spec/openapi_v3_1/style_features_spec.rb`

## Implementation

- `lib/grape-swagger/endpoint.rb`
- `lib/grape-swagger/openapi/response_content_builder.rb`
