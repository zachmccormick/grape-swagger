# Example Object

Holds a reusable example for use in various places in the specification.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `summary` | string | No | :white_check_mark: | Short description of the example |
| `description` | string | No | :white_check_mark: | Long description. CommonMark syntax MAY be used for rich text representation |
| `value` | any | No | :white_check_mark: | Embedded literal example. Mutually exclusive with `externalValue` |
| `externalValue` | string | No | :x: | URL pointing to the literal example. Mutually exclusive with `value` |

**Note:** `value` and `externalValue` are mutually exclusive. The spec states: "This provides the capability to reference examples that cannot easily be included in JSON or YAML documents."

## Current Support

grape-swagger supports Example Objects with the following fields:
- ✅ `summary` - Supported in named examples
- ✅ `description` - Supported in named examples
- ✅ `value` - Fully supported for inline examples
- ❌ `externalValue` - Not supported

### Inline Examples vs Named Examples

grape-swagger supports two forms of examples:

1. **Inline examples** - A single example value per media type (becomes `example` in OpenAPI)
2. **Named examples** - Multiple examples with `summary`, `description`, and `value` fields (becomes `examples` map in OpenAPI)

### Reusable Examples

Reusable examples in `components/examples` are not currently supported. All examples must be defined inline within response or parameter definitions.

## Usage

### Inline Examples (Supported)

```ruby
desc 'Get user',
     success: {
       model: UserEntity,
       examples: {
         'application/json' => {
           id: 1,
           name: 'John Doe',
           email: 'john@example.com'
         }
       }
     }
get '/users/:id' do
  # ...
end
```

### Multiple Examples (Supported)

```ruby
desc 'Get user',
     success: {
       model: UserEntity,
       examples: {
         'application/json' => [
           { id: 1, name: 'John Doe', email: 'john@example.com' },
           { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
         ]
       }
     }
get '/users/:id' do
  # ...
end
```

### Failure Examples (Supported)

```ruby
desc 'Get user',
     failure: [
       {
         code: 404,
         message: 'Not Found',
         examples: {
           'application/json' => { error: 'User not found', code: 'USER_NOT_FOUND' }
         }
       }
     ]
get '/users/:id' do
  # ...
end
```

## Output Example

```json
{
  "responses": {
    "200": {
      "description": "Success",
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
  }
}
```

## Reusable Examples (Not Supported)

The OpenAPI spec allows defining reusable examples in `components/examples`:

```json
{
  "components": {
    "examples": {
      "UserExample": {
        "summary": "A typical user",
        "value": {
          "id": 1,
          "name": "John Doe"
        }
      }
    }
  }
}
```

This is not currently supported.

## Tests

- `spec/openapi_v3_1/style_features_spec.rb`
- `spec/swagger_v2/api_swagger_v2_response_spec.rb`

## Implementation

- `lib/grape-swagger/endpoint.rb`
- `lib/grape-swagger/doc_methods/status_codes.rb`

## TODO

- [ ] Add support for reusable examples in `components/examples`
- [ ] Add `externalValue` support for referencing external example files
- [ ] Add support for Example Objects in parameter definitions (currently only in responses)
