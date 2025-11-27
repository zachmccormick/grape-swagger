# Reference Object

A simple object to allow referencing other components in the OpenAPI document.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `$ref` | string | Yes | :white_check_mark: | Reference URI |
| `summary` | string | No | :x: | Override summary (3.1.0) |
| `description` | string | No | :x: | Override description (3.1.0) |

## Reference Format

References use JSON Pointer syntax:

```
#/components/{type}/{name}
```

## Supported Reference Types

| Type | Path | Supported |
|------|------|-----------|
| schemas | `#/components/schemas/{name}` | :white_check_mark: |
| responses | `#/components/responses/{name}` | :x: |
| parameters | `#/components/parameters/{name}` | :x: |
| examples | `#/components/examples/{name}` | :x: |
| requestBodies | `#/components/requestBodies/{name}` | :x: |
| headers | `#/components/headers/{name}` | :x: |
| securitySchemes | `#/components/securitySchemes/{name}` | :white_check_mark: |
| links | `#/components/links/{name}` | :x: |
| callbacks | `#/components/callbacks/{name}` | :x: |
| pathItems | `#/components/pathItems/{name}` | :x: |

## Usage

### Schema References (Automatic)

```ruby
class UserEntity < Grape::Entity
  expose :id, documentation: { type: Integer }
  expose :name, documentation: { type: String }
end

desc 'Get user',
     success: UserEntity
get '/users/:id' do
  # Generates: { "$ref": "#/components/schemas/User" }
end
```

### Nested Entity References

```ruby
class AddressEntity < Grape::Entity
  expose :street, documentation: { type: String }
  expose :city, documentation: { type: String }
end

class UserEntity < Grape::Entity
  expose :id, documentation: { type: Integer }
  expose :address, using: AddressEntity, documentation: { type: AddressEntity }
end

# Generates reference to AddressEntity in User schema
```

### Array of References

```ruby
class OrderEntity < Grape::Entity
  expose :id, documentation: { type: Integer }
  expose :items, using: OrderItemEntity, documentation: { type: Array, is_array: true }
end

# Generates:
# "items": {
#   "type": "array",
#   "items": { "$ref": "#/components/schemas/OrderItem" }
# }
```

## Output Example

```json
{
  "paths": {
    "/users/{id}": {
      "get": {
        "responses": {
          "200": {
            "description": "Success",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/User"
                }
              }
            }
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "User": {
        "type": "object",
        "properties": {
          "id": { "type": "integer", "format": "int32" },
          "name": { "type": "string" },
          "address": { "$ref": "#/components/schemas/Address" }
        }
      },
      "Address": {
        "type": "object",
        "properties": {
          "street": { "type": "string" },
          "city": { "type": "string" }
        }
      }
    }
  }
}
```

## Tests

- `spec/swagger_v2/api_swagger_v2_mounted_spec.rb`
- `spec/lib/move_params_spec.rb`

## Implementation

- `lib/grape-swagger/endpoint.rb`
- `lib/grape-swagger/doc_methods/move_params.rb`
- `lib/grape-swagger/openapi/schema_resolver.rb`

## OpenAPI 3.1.0 Enhancements

In OpenAPI 3.1.0, references can include `summary` and `description` to override the referenced object:

```json
{
  "$ref": "#/components/schemas/User",
  "summary": "A brief user summary",
  "description": "Extended description overriding the original"
}
```

This is not currently supported.

## TODO

- [ ] Add summary/description override support (3.1.0)
- [ ] Add support for external references
- [ ] Add reusable responses support
- [ ] Add reusable parameters support
