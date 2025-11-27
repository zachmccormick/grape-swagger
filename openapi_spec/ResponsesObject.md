# Responses Object

A container for the expected responses of an operation.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `default` | [Response Object](ResponseObject.md) \| Reference Object | No | :construction: | Default response |
| `{HTTP Status Code}` | [Response Object](ResponseObject.md) \| Reference Object | No | :white_check_mark: | Status-specific response |

## Supported Status Codes

| Code | Support | Notes |
|------|---------|-------|
| 200 | :white_check_mark: | From `success:` in desc |
| 201 | :white_check_mark: | Auto for POST when model present |
| 204 | :white_check_mark: | From `failure:` or status codes |
| 4xx | :white_check_mark: | From `failure:` array |
| 5xx | :white_check_mark: | From `failure:` array |
| default | :construction: | Partial support |

## Usage

```ruby
desc 'Get a user' do
  success model: Entities::User
  failure [
    { code: 400, message: 'Bad Request' },
    { code: 401, message: 'Unauthorized' },
    { code: 404, message: 'Not Found', model: Entities::Error },
    { code: 500, message: 'Internal Server Error' }
  ]
end
get ':id' do
  # ...
end
```

## Output Example

```json
{
  "responses": {
    "200": {
      "description": "Get a user",
      "content": {
        "application/json": {
          "schema": {
            "$ref": "#/components/schemas/User"
          }
        }
      }
    },
    "400": {
      "description": "Bad Request"
    },
    "401": {
      "description": "Unauthorized"
    },
    "404": {
      "description": "Not Found",
      "content": {
        "application/json": {
          "schema": {
            "$ref": "#/components/schemas/Error"
          }
        }
      }
    },
    "500": {
      "description": "Internal Server Error"
    }
  }
}
```

## Custom Status Codes

```ruby
desc 'Process payment' do
  success model: Entities::Payment
  failure [
    { code: 402, message: 'Payment Required', model: Entities::PaymentError },
    { code: 409, message: 'Conflict - Already processed' },
    { code: 422, message: 'Unprocessable Entity' }
  ]
end
```

## Tests

- `spec/swagger_v2/api_swagger_v2_response_spec.rb`
- `spec/swagger_v2/api_swagger_v2_status_codes_spec.rb`
- `spec/openapi_v3_1/style_features_spec.rb`

## Implementation

- `lib/grape-swagger/doc_methods/status_codes.rb`
- `lib/grape-swagger/endpoint.rb`
