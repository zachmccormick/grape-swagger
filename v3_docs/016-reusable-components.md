# PR 16: Reusable Components

## Overview

Adds support for OpenAPI 3.1.0 reusable components via a class-based DSL. This includes:

- **ComponentsRegistry**: Central registry for all reusable component types (parameters, responses, headers, examples, request bodies, path items)
- **ReusableParameter**: DSL for defining reusable parameter components
- **ReusableResponse**: DSL for defining reusable response components
- **ReusableHeader**: DSL for defining reusable header components
- **ParamsExtensions**: `ref` DSL for referencing reusable parameters in Grape params blocks
- **Response references**: Symbol models in failure arrays generate `$ref` to `#/components/responses/`

## ComponentsRegistry

Central class-level registry that stores all reusable component classes:

```ruby
GrapeSwagger::ComponentsRegistry.register_parameter(klass)
GrapeSwagger::ComponentsRegistry.find_parameter!('PageParam')
GrapeSwagger::ComponentsRegistry.to_openapi  # => { parameters: {...}, responses: {...}, ... }
GrapeSwagger::ComponentsRegistry.reset!       # clears all registries
```

Auto-registration happens via the `inherited` hook on each reusable base class. Collision warnings are emitted when two classes register with the same component name.

## ReusableParameter

```ruby
class PageParam < GrapeSwagger::ReusableParameter
  name 'page'
  in_query
  schema type: 'integer', default: 1, minimum: 1
  description 'Page number for pagination'
  required false
end
```

Convenience methods: `in_query`, `in_path`, `in_header`, `in_cookie`.

## ReusableResponse

```ruby
class NotFoundResponse < GrapeSwagger::ReusableResponse
  description 'Resource not found'
  content 'application/json', schema: { type: 'object', properties: { error: { type: 'string' } } }
end
```

Shorthand: `json_schema(entity_or_schema)` sets `content 'application/json'`.

## ReusableHeader

```ruby
class RateLimitHeader < GrapeSwagger::ReusableHeader
  description 'Requests remaining'
  schema type: 'integer'
  example 99
end
```

## ref DSL (ParamsExtensions)

Use `ref :ComponentName` inside a `params` block to reference a registered parameter:

```ruby
params do
  ref :PageParam
  ref :PerPageParam
  optional :filter, type: String
end
```

This generates `$ref: '#/components/parameters/PageParam'` in the OpenAPI output while also registering the actual Grape parameter for runtime validation.

## Response References

Use a Symbol as the model in failure arrays to generate a response `$ref`:

```ruby
desc 'Get user',
  failure: [
    { code: 404, model: :NotFoundResponse },
    { code: 401, model: :UnauthorizedResponse }
  ]
```

Generates: `"404": { "$ref": "#/components/responses/NotFoundResponse" }`

## Pipeline Integration

The ComponentsRegistry output is automatically merged into the `components` section of the OpenAPI document during doc generation.

## Files

- `lib/grape-swagger/components_registry.rb`
- `lib/grape-swagger/reusable_parameter.rb`
- `lib/grape-swagger/reusable_response.rb`
- `lib/grape-swagger/reusable_header.rb`
- `lib/grape-swagger/endpoint/params_extensions.rb`
- `spec/grape-swagger/components_registry_spec.rb`
- `spec/grape-swagger/reusable_parameter_spec.rb`
- `spec/grape-swagger/reusable_response_spec.rb`
- `spec/grape-swagger/reusable_header_spec.rb`
- `spec/grape-swagger/endpoint/params_extensions_spec.rb`
- `spec/grape-swagger/openapi/reusable_components_integration_spec.rb`
