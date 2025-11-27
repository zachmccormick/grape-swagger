# Media Type Object

Provides schema and examples for a media type. Each Media Type Object provides schema and examples for the media types identified by its key.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `schema` | [Schema Object](SchemaObject.md) | No | :white_check_mark: | The schema defining the content of the request, response, or parameter |
| `example` | any | No | :white_check_mark: | Example of the media type. The example value SHALL override any example in the schema. Mutually exclusive with `examples` |
| `examples` | Map[string, [Example Object](ExampleObject.md) \| Reference Object] | No | :white_check_mark: | Examples of the media type. Each example SHALL override any example in the schema. Mutually exclusive with `example` |
| `encoding` | Map[string, [Encoding Object](EncodingObject.md)] | No | :construction: | A map between a property name and its encoding information. The key MUST exist in the schema as a property. Only applies to `requestBody` when media type is `multipart` or `application/x-www-form-urlencoded` |

## Usage

### Response with Example

```ruby
desc 'Get a user' do
  success model: Entities::User, examples: {
    'application/json' => { id: 1, name: 'John Doe', email: 'john@example.com' }
  }
end
get ':id' do
  # ...
end
```

### Request Body with Example

```ruby
desc 'Create a user' do
  success model: Entities::User
end
params do
  requires :name, type: String, desc: 'User name'
  requires :email, type: String, desc: 'User email'
end
post do
  # Example would be derived from params or entity
end
```

## Output Example

```json
{
  "content": {
    "application/json": {
      "schema": {
        "$ref": "#/components/schemas/User"
      },
      "example": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com"
      }
    }
  }
}
```

## Multiple Examples

```json
{
  "content": {
    "application/json": {
      "schema": {
        "$ref": "#/components/schemas/User"
      },
      "examples": {
        "admin": {
          "summary": "Admin user",
          "value": { "id": 1, "name": "Admin", "role": "admin" }
        },
        "regular": {
          "summary": "Regular user",
          "value": { "id": 2, "name": "User", "role": "user" }
        }
      }
    }
  }
}
```

## Important Notes

### Example vs Examples
Per the OpenAPI 3.1.0 specification:
- The `example` and `examples` fields are **mutually exclusive**
- If either is provided, it overrides any example in the schema
- Use `example` for a single example value
- Use `examples` for multiple named examples with optional summaries and descriptions

### Encoding Field
- The `encoding` field SHALL only apply to Request Body Objects
- Only applies when the media type is `multipart` or `application/x-www-form-urlencoded`
- The property name key in the encoding map MUST exist in the schema as a property
- See [Encoding Object](EncodingObject.md) for detailed field information

## Tests

- `spec/openapi_v3_1/style_features_spec.rb` - Style features and examples
- `spec/grape-swagger/openapi/response_content_builder_spec.rb` - Response content and examples
- `spec/grape-swagger/openapi/request_body_builder_spec.rb` - Request body content and examples
- `spec/lib/openapi/encoding_builder_spec.rb` - Encoding object builder (unit tests)
- `spec/lib/openapi/content_negotiator_spec.rb` - Content negotiation with encoding

## Implementation

- `lib/grape-swagger/openapi/response_content_builder.rb` - Builds response Media Type Objects
- `lib/grape-swagger/openapi/request_body_builder.rb` - Builds request body Media Type Objects
- `lib/grape-swagger/openapi/encoding_builder.rb` - Builds Encoding Objects (implemented but not integrated)
- `lib/grape-swagger/openapi/content_negotiator.rb` - Contains `add_encoding` method (not yet integrated)

## Current Status

### Fully Supported (✅)
- `schema` field with full Schema Object support
- `example` field (single example)
- `examples` field (multiple named examples with Example Objects)
- Proper mutual exclusivity between `example` and `examples`
- Media type negotiation and prioritization

### Partial Support (:construction:)
- `encoding` field:
  - ✅ `EncodingBuilder` class fully implemented with all fields (`contentType`, `headers`, `style`, `explode`, `allowReserved`)
  - ✅ `ContentNegotiator.add_encoding` method implemented
  - ✅ Full unit test coverage
  - ❌ **Not integrated** into `RequestBodyBuilder.build_media_type_object`
  - ❌ **Not demonstrated** in demo app

## TODO

- [ ] Integrate `encoding` support into request body Media Type Objects
- [ ] Add demo app example showing multipart file upload with encoding
