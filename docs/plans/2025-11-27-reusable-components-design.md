# Reusable Components Design

**Date:** 2025-11-27
**Status:** Approved
**Author:** Claude + Zach McCormick

## Overview

Add auto-generation and referencing support for OpenAPI reusable components (parameters, responses, headers) using a Grape::Entity-style class-based DSL.

## Goals

1. Define reusable components using Ruby classes (familiar pattern)
2. Auto-register components when classes are loaded
3. Reference components from endpoints using `$ref`
4. Maintain Grape runtime validation while generating OpenAPI `$ref`

## Non-Goals

- Reusable `requestBodies`, `examples`, `links`, `callbacks` (future work)
- External file references
- Component inheritance/composition

## Architecture

### New Base Classes

Three new base classes following the Grape::Entity pattern:

```
GrapeSwagger::ReusableParameter
GrapeSwagger::ReusableResponse
GrapeSwagger::ReusableHeader
```

### Central Registry

```
GrapeSwagger::Components
  .parameters  -> Hash of registered parameter classes
  .responses   -> Hash of registered response classes
  .headers     -> Hash of registered header classes
  .to_openapi  -> Builds components hash for OpenAPI output
  .reset!      -> Clears registry (for testing)
```

## Detailed Design

### ReusableParameter

```ruby
class PageParam < GrapeSwagger::ReusableParameter
  name 'page'
  in_query                    # or in_path, in_header, in_cookie
  schema type: 'integer', default: 1, minimum: 1
  description 'Page number'
  required false              # optional, defaults to false
  deprecated false            # optional
  example 1                   # optional
end
```

**DSL Methods:**
- `name(string)` - Parameter name (required)
- `in_query`, `in_path`, `in_header`, `in_cookie` - Location (required)
- `schema(hash)` - JSON Schema for the parameter
- `description(string)` - Human-readable description
- `required(bool)` - Whether parameter is required
- `deprecated(bool)` - Deprecation flag
- `example(any)` - Example value
- `component_name(string)` - Override auto-derived name

### ReusableResponse

```ruby
class NotFoundResponse < GrapeSwagger::ReusableResponse
  description 'Resource not found'
  json_schema ErrorEntity     # Shorthand for application/json

  # Or explicit content:
  # content 'application/json', schema: ErrorEntity
  # content 'application/xml', schema: ErrorXmlEntity
end
```

**DSL Methods:**
- `description(string)` - Response description (required)
- `content(media_type, schema:)` - Add content type with schema
- `json_schema(entity_or_hash)` - Shorthand for JSON content
- `headers(&block)` - Response headers
- `component_name(string)` - Override auto-derived name

### ReusableHeader

```ruby
class RateLimitHeader < GrapeSwagger::ReusableHeader
  description 'Requests remaining in current window'
  schema type: 'integer'
  example 99
  required false
end
```

**DSL Methods:**
- `description(string)` - Header description
- `schema(hash)` - JSON Schema for the header value
- `required(bool)` - Whether header is required
- `deprecated(bool)` - Deprecation flag
- `example(any)` - Example value
- `component_name(string)` - Override auto-derived name

### Auto-Registration

Components auto-register when Ruby loads the class via `inherited` hook:

```ruby
class ReusableParameter
  def self.inherited(subclass)
    GrapeSwagger::Components.register_parameter(subclass)
  end
end
```

### Referencing in Endpoints

**Parameters:**
```ruby
params do
  ref :PageParam        # Generates $ref AND applies Grape validation
  ref :PerPageParam
  optional :filter, type: String  # Inline params still work
end
```

**Responses:**
```ruby
desc 'Get user',
  success: UserEntity,
  failure: [
    { code: 404, model: :NotFoundResponse },   # Symbol = $ref
    { code: 422, model: ValidationEntity }     # Class = inline
  ]
```

### Generated OpenAPI

```json
{
  "paths": {
    "/users": {
      "get": {
        "parameters": [
          { "$ref": "#/components/parameters/PageParam" },
          { "$ref": "#/components/parameters/PerPageParam" }
        ],
        "responses": {
          "404": { "$ref": "#/components/responses/NotFoundResponse" }
        }
      }
    }
  },
  "components": {
    "parameters": {
      "PageParam": {
        "name": "page",
        "in": "query",
        "schema": { "type": "integer", "default": 1, "minimum": 1 },
        "description": "Page number"
      }
    },
    "responses": {
      "NotFoundResponse": {
        "description": "Resource not found",
        "content": {
          "application/json": {
            "schema": { "$ref": "#/components/schemas/Error" }
          }
        }
      }
    }
  }
}
```

## Error Handling

### Name Collisions

```ruby
# Warning on collision
[grape-swagger] Component name collision: PageParam already registered
by Api::V1::PageParam, now being overwritten by Api::V2::PageParam.
Use `component_name 'UniqueNameHere'` to resolve.
```

### Missing References

```ruby
# Error on missing component
GrapeSwagger::ComponentNotFoundError: Parameter component 'InvalidParam'
not found. Available: PageParam, PerPageParam
```

## File Structure

```
lib/grape-swagger/
  reusable_parameter.rb      # Base class
  reusable_response.rb       # Base class
  reusable_header.rb         # Base class
  components.rb              # Registry (extend existing)
  endpoint_extensions.rb     # `ref` DSL method
  openapi/
    components_builder.rb    # Merge auto-registered (modify existing)
```

## Testing Strategy

1. **Unit tests** for each base class DSL
2. **Unit tests** for registry (register, lookup, collision)
3. **Integration tests** for `ref` in params block
4. **Integration tests** for response references
5. **End-to-end tests** verifying complete OpenAPI output

## Migration Path

- Fully backwards compatible
- Existing manual `components:` option continues to work
- Auto-registered components merge with manual ones
- No breaking changes to existing APIs

## Future Considerations

- `requestBodies` component type
- `examples` component type
- `links` component type
- `callbacks` component type
- Component inheritance (extend another component)
- Shared schemas between parameters and responses
