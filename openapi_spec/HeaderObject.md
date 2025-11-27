# Header Object

Describes a single header parameter. Follows the same structure as Parameter Object, but without `name` and `in`.

## Specification Notes

- The Header Object inherits all fields from the Parameter Object except `name` and `in`
- Header name comes from the map key where the header is defined
- Location (`in`) is implicitly "header" and cannot be overridden
- `schema` and `content` are mutually exclusive (use one or the other)
- Default `style` for headers is `simple` when using `schema`

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `description` | string | No | :white_check_mark: | Header description (supports CommonMark) |
| `required` | boolean | No | :white_check_mark: | Whether header is required |
| `deprecated` | boolean | No | :x: | Not implemented |
| `allowEmptyValue` | boolean | No | :x: | Not implemented |
| `style` | string | No | :white_check_mark: | Serialization style (default: `simple`) |
| `explode` | boolean | No | :x: | Separate params for array/object values |
| `allowReserved` | boolean | No | :x: | Allow RFC3986 reserved characters |
| `schema` | [Schema Object](SchemaObject.md) | No | :white_check_mark: | Header schema definition |
| `example` | any | No | :white_check_mark: | Single example value |
| `examples` | Map[string, [Example Object](ExampleObject.md)] | No | :x: | Multiple named examples |
| `content` | Map[string, [Media Type Object](MediaTypeObject.md)] | No | :x: | Alternative to schema for complex types |

## Usage

```ruby
desc 'Get paginated users' do
  success model: Entities::User, headers: {
    'X-Total-Count' => {
      description: 'Total number of users',
      schema: { type: 'integer' }
    },
    'X-Page' => {
      description: 'Current page number',
      schema: { type: 'integer' }
    },
    'X-Per-Page' => {
      description: 'Items per page',
      schema: { type: 'integer' }
    },
    'Link' => {
      description: 'Pagination links',
      schema: { type: 'string' },
      example: '<https://api.example.com/users?page=2>; rel="next"'
    }
  }
end
get do
  header['X-Total-Count'] = User.count.to_s
  present users, with: Entities::User
end
```

## Output Example

```json
{
  "200": {
    "description": "Get paginated users",
    "headers": {
      "X-Total-Count": {
        "description": "Total number of users",
        "schema": {
          "type": "integer"
        }
      },
      "X-Page": {
        "description": "Current page number",
        "schema": {
          "type": "integer"
        }
      },
      "Link": {
        "description": "Pagination links",
        "schema": {
          "type": "string"
        },
        "example": "<https://api.example.com/users?page=2>; rel=\"next\""
      }
    },
    "content": { ... }
  }
}
```

## Tests

### Swagger 2.0 Tests
- `spec/swagger_v2/api_swagger_v2_response_with_headers_spec.rb` - Response headers
- `spec/swagger_v2/api_swagger_v2_headers_spec.rb` - Request headers

### OpenAPI 3.1.0 Tests
- `spec/openapi_v3_1/parameter_schema_wrapping_spec.rb` - Header schema wrapping and style
- `spec/grape-swagger/openapi/response_content_builder_spec.rb` - Headers in responses
- `spec/grape-swagger/openapi/components_builder_spec.rb` - Reusable header components
- `spec/lib/openapi/encoding_builder_spec.rb` - Headers in encoding objects

## Implementation

- `lib/grape-swagger/endpoint.rb` - Main endpoint processing
- `lib/grape-swagger/openapi/header_builder.rb` - OpenAPI 3.1.0 Header Object builder (not yet integrated)
- `lib/grape-swagger/openapi/response_content_builder.rb` - Includes headers in responses (line 33)

## TODO

### High Priority
- [ ] Add `deprecated` support
- [ ] Add `examples` (multiple named examples) support
- [ ] Integrate HeaderBuilder into response processing pipeline

### Medium Priority
- [ ] Add `allowEmptyValue` support
- [ ] Add `explode` support

### Low Priority
- [ ] Add `allowReserved` support
- [ ] Add `content` support (alternative to schema for complex headers)
