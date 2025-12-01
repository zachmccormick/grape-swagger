# Reusable Components DSL

grape-swagger provides a DSL for defining reusable OpenAPI components using Ruby classes. This feature allows you to define parameters, responses, and headers once and reference them across multiple endpoints, following the DRY (Don't Repeat Yourself) principle.

## Overview

The reusable components system consists of three base classes:
- `GrapeSwagger::ReusableParameter` - For defining reusable parameters
- `GrapeSwagger::ReusableResponse` - For defining reusable responses
- `GrapeSwagger::ReusableHeader` - For defining reusable headers

These classes auto-register using Ruby's `inherited` hook, similar to how `Grape::Entity` works. Once defined, they are automatically included in the `components` section of your OpenAPI document.

## ReusableParameter

Define reusable parameters that can be referenced across multiple endpoints using the `ref` method in your params block.

### Basic Usage

```ruby
class PageParam < GrapeSwagger::ReusableParameter
  name 'page'
  in_query
  schema type: 'integer', default: 1, minimum: 1
  description 'Page number for pagination'
  required false
end

class PerPageParam < GrapeSwagger::ReusableParameter
  name 'per_page'
  in_query
  schema type: 'integer', default: 20, minimum: 1, maximum: 100
  description 'Number of items per page'
  required false
end
```

### Using References in Endpoints

```ruby
class API < Grape::API
  desc 'List items'
  params do
    ref :PageParam
    ref :PerPageParam
    optional :filter, type: String, desc: 'Filter string'
  end
  get '/items' do
    { items: [], page: params[:page], per_page: params[:per_page] }
  end
end
```

### Parameter DSL Methods

| Method | Required | Description |
|--------|----------|-------------|
| `name(string)` | Yes | Parameter name |
| `in_query` | Yes* | Set parameter location to query |
| `in_path` | Yes* | Set parameter location to path |
| `in_header` | Yes* | Set parameter location to header |
| `in_cookie` | Yes* | Set parameter location to cookie |
| `schema(hash)` | Yes | OpenAPI schema definition |
| `description(string)` | No | Human-readable description |
| `required(boolean)` | No | Whether parameter is required |
| `deprecated(boolean)` | No | Mark parameter as deprecated |
| `example(value)` | No | Example value |

*One location method is required

### Parameter Locations

#### Query Parameters
```ruby
class SortParam < GrapeSwagger::ReusableParameter
  name 'sort'
  in_query
  schema type: 'string', enum: ['asc', 'desc']
  description 'Sort order'
end
```

#### Path Parameters
```ruby
class IdParam < GrapeSwagger::ReusableParameter
  name 'id'
  in_path
  schema type: 'integer'
  description 'Resource ID'
  required true
end
```

#### Header Parameters
```ruby
class ApiVersionParam < GrapeSwagger::ReusableParameter
  name 'X-API-Version'
  in_header
  schema type: 'string'
  description 'API version'
  example 'v1'
end
```

#### Cookie Parameters
```ruby
class SessionParam < GrapeSwagger::ReusableParameter
  name 'session_id'
  in_cookie
  schema type: 'string'
  description 'Session identifier'
  required true
end
```

### Advanced Schema Options

```ruby
class AdvancedParam < GrapeSwagger::ReusableParameter
  name 'quantity'
  in_query
  schema type: 'integer',
         minimum: 1,
         maximum: 1000,
         default: 10,
         multipleOf: 5
  description 'Quantity must be between 1 and 1000, divisible by 5'
  example 50
end
```

### Custom Component Names

By default, the component name is derived from the class name. You can override this:

```ruby
class Api::V2::PageParam < GrapeSwagger::ReusableParameter
  component_name 'V2PageParam'  # Avoids collision with Api::V1::PageParam

  name 'page'
  in_query
  schema type: 'integer', default: 1
end
```

### Generated OpenAPI Output

```json
{
  "components": {
    "parameters": {
      "PageParam": {
        "name": "page",
        "in": "query",
        "schema": {
          "type": "integer",
          "default": 1,
          "minimum": 1
        },
        "description": "Page number for pagination",
        "required": false
      }
    }
  },
  "paths": {
    "/items": {
      "get": {
        "parameters": [
          { "$ref": "#/components/parameters/PageParam" },
          { "$ref": "#/components/parameters/PerPageParam" },
          {
            "name": "filter",
            "in": "query",
            "schema": { "type": "string" },
            "description": "Filter string"
          }
        ]
      }
    }
  }
}
```

## ReusableResponse

Define reusable responses for common HTTP status codes and error scenarios.

### Basic Usage

```ruby
class NotFoundResponse < GrapeSwagger::ReusableResponse
  description 'The requested resource was not found'
  json_schema(
    type: 'object',
    properties: {
      error: { type: 'string' },
      code: { type: 'integer' }
    }
  )
end

class UnauthorizedResponse < GrapeSwagger::ReusableResponse
  description 'Authentication is required'
  json_schema(
    type: 'object',
    properties: {
      message: { type: 'string' }
    }
  )
end
```

### Using Symbol Models in Endpoints

Reference reusable responses using Symbol models in the `failure` array:

```ruby
class API < Grape::API
  desc 'Get item',
       success: { code: 200, message: 'Success' },
       failure: [
         { code: 404, model: :NotFoundResponse },
         { code: 401, model: :UnauthorizedResponse }
       ]
  get '/items/:id' do
    { id: params[:id] }
  end
end
```

### Response DSL Methods

| Method | Required | Description |
|--------|----------|-------------|
| `description(string)` | Yes | Human-readable description |
| `json_schema(hash/entity)` | No | Shorthand for `content 'application/json', schema: ...` |
| `content(media_type, opts)` | No | Add content type with schema |
| `headers(&block)` | No | Define response headers (future feature) |

### Using Grape::Entity as Schema

```ruby
class ErrorEntity < Grape::Entity
  expose :error, documentation: { type: String, desc: 'Error message' }
  expose :code, documentation: { type: Integer, desc: 'Error code' }
end

class NotFoundResponse < GrapeSwagger::ReusableResponse
  description 'Resource not found'
  json_schema ErrorEntity
end
```

### Multiple Content Types

```ruby
class MultiFormatResponse < GrapeSwagger::ReusableResponse
  description 'Success response in multiple formats'

  content 'application/json',
          schema: { type: 'object', properties: { data: { type: 'string' } } }

  content 'application/xml',
          schema: { type: 'object', properties: { data: { type: 'string' } } }
end
```

### Common Error Responses

Here are some standard error responses you might define:

```ruby
class BadRequestResponse < GrapeSwagger::ReusableResponse
  description 'The request was malformed or invalid'
  json_schema(
    type: 'object',
    required: ['error'],
    properties: {
      error: { type: 'string' },
      details: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            field: { type: 'string' },
            message: { type: 'string' }
          }
        }
      }
    }
  )
end

class ValidationErrorResponse < GrapeSwagger::ReusableResponse
  description 'Request validation failed'
  json_schema(
    type: 'object',
    required: ['message', 'errors'],
    properties: {
      message: { type: 'string' },
      errors: {
        type: 'object',
        additionalProperties: {
          type: 'array',
          items: { type: 'string' }
        }
      }
    }
  )
end

class RateLimitResponse < GrapeSwagger::ReusableResponse
  description 'Rate limit exceeded'
  json_schema(
    type: 'object',
    properties: {
      message: { type: 'string' },
      retry_after: { type: 'integer' }
    }
  )
end

class InternalErrorResponse < GrapeSwagger::ReusableResponse
  description 'An internal server error occurred'
  json_schema(
    type: 'object',
    properties: {
      error: { type: 'string' },
      request_id: { type: 'string', format: 'uuid' }
    }
  )
end
```

### Custom Component Names

```ruby
class Api::V2::NotFoundResponse < GrapeSwagger::ReusableResponse
  component_name 'V2NotFound'

  description 'V2 API: Resource not found'
  json_schema(type: 'object', properties: { error: { type: 'string' } })
end
```

### Generated OpenAPI Output

```json
{
  "components": {
    "responses": {
      "NotFoundResponse": {
        "description": "The requested resource was not found",
        "content": {
          "application/json": {
            "schema": {
              "type": "object",
              "properties": {
                "error": { "type": "string" },
                "code": { "type": "integer" }
              }
            }
          }
        }
      }
    }
  },
  "paths": {
    "/items/{id}": {
      "get": {
        "responses": {
          "200": {
            "description": "Success"
          },
          "404": {
            "$ref": "#/components/responses/NotFoundResponse"
          },
          "401": {
            "$ref": "#/components/responses/UnauthorizedResponse"
          }
        }
      }
    }
  }
}
```

## ReusableHeader

Define reusable header definitions that can be referenced in responses.

### Basic Usage

```ruby
class RateLimitHeader < GrapeSwagger::ReusableHeader
  description 'Number of requests remaining in current rate limit window'
  schema type: 'integer'
  example 99
end

class RequestIdHeader < GrapeSwagger::ReusableHeader
  description 'Unique identifier for this request'
  schema type: 'string', format: 'uuid'
  example 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
end
```

### Header DSL Methods

| Method | Required | Description |
|--------|----------|-------------|
| `description(string)` | Yes | Human-readable description |
| `schema(hash)` | Yes | OpenAPI schema definition |
| `required(boolean)` | No | Whether header is required |
| `deprecated(boolean)` | No | Mark header as deprecated |
| `example(value)` | No | Example value |

### Common Headers

```ruby
class PaginationTotalHeader < GrapeSwagger::ReusableHeader
  description 'Total number of items available'
  schema type: 'integer'
  required false
end

class PaginationPageHeader < GrapeSwagger::ReusableHeader
  description 'Current page number'
  schema type: 'integer'
  required false
end

class ETagHeader < GrapeSwagger::ReusableHeader
  description 'Entity tag for cache validation'
  schema type: 'string'
  example '"33a64df551425fcc55e4d42a148795d9f25f89d4"'
end

class ContentVersionHeader < GrapeSwagger::ReusableHeader
  description 'API version of the response content'
  schema type: 'string'
  example 'v2'
end
```

### Generated OpenAPI Output

```json
{
  "components": {
    "headers": {
      "RateLimitHeader": {
        "description": "Number of requests remaining in current rate limit window",
        "schema": {
          "type": "integer"
        },
        "example": 99
      },
      "RequestIdHeader": {
        "description": "Unique identifier for this request",
        "schema": {
          "type": "string",
          "format": "uuid"
        },
        "example": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
      }
    }
  }
}
```

## Best Practices

### Organizing Reusable Components

Create a dedicated directory structure for your reusable components:

```
app/
  api/
    components/
      parameters/
        pagination_params.rb
        filter_params.rb
      responses/
        error_responses.rb
        success_responses.rb
      headers/
        standard_headers.rb
```

Example file structure:

```ruby
# app/api/components/parameters/pagination_params.rb
class PageParam < GrapeSwagger::ReusableParameter
  name 'page'
  in_query
  schema type: 'integer', default: 1, minimum: 1
  description 'Page number'
end

class PerPageParam < GrapeSwagger::ReusableParameter
  name 'per_page'
  in_query
  schema type: 'integer', default: 20, minimum: 1, maximum: 100
  description 'Items per page'
end
```

```ruby
# app/api/components/responses/error_responses.rb
class NotFoundResponse < GrapeSwagger::ReusableResponse
  description 'Resource not found'
  json_schema(type: 'object', properties: { error: { type: 'string' } })
end

class UnauthorizedResponse < GrapeSwagger::ReusableResponse
  description 'Unauthorized access'
  json_schema(type: 'object', properties: { message: { type: 'string' } })
end
```

### Loading Components

Ensure your components are loaded before your API definitions:

```ruby
# config/initializers/grape_swagger.rb
Dir[Rails.root.join('app/api/components/**/*.rb')].each { |f| require f }
```

### Naming Conventions

- Use descriptive class names that end with the component type:
  - Parameters: `PageParam`, `FilterParam`
  - Responses: `NotFoundResponse`, `ValidationErrorResponse`
  - Headers: `RateLimitHeader`, `PaginationHeader`

- Avoid name collisions by using namespaces or the `component_name` method

### Runtime Validation

The `ref` method not only generates OpenAPI documentation but also applies runtime validation in Grape:

```ruby
params do
  ref :PageParam  # Applies Grape validation for 'page' parameter
end
```

This ensures your API behavior matches your documentation.

### Component Name Collisions

If you have multiple versions of an API with similarly named components, use custom component names:

```ruby
class Api::V1::PageParam < GrapeSwagger::ReusableParameter
  component_name 'V1PageParam'
  # ...
end

class Api::V2::PageParam < GrapeSwagger::ReusableParameter
  component_name 'V2PageParam'
  # ...
end
```

The registry will warn you if there's a collision, but it will still overwrite. Using custom names prevents this.

## Migration Guide

### From Inline Parameters to Reusable Parameters

Before:
```ruby
desc 'List items'
params do
  optional :page, type: Integer, default: 1, desc: 'Page number'
  optional :per_page, type: Integer, default: 20, desc: 'Items per page'
end
get '/items' do
  # ...
end

desc 'List users'
params do
  optional :page, type: Integer, default: 1, desc: 'Page number'
  optional :per_page, type: Integer, default: 20, desc: 'Items per page'
end
get '/users' do
  # ...
end
```

After:
```ruby
class PageParam < GrapeSwagger::ReusableParameter
  name 'page'
  in_query
  schema type: 'integer', default: 1
  description 'Page number'
end

class PerPageParam < GrapeSwagger::ReusableParameter
  name 'per_page'
  in_query
  schema type: 'integer', default: 20
  description 'Items per page'
end

desc 'List items'
params do
  ref :PageParam
  ref :PerPageParam
end
get '/items' do
  # ...
end

desc 'List users'
params do
  ref :PageParam
  ref :PerPageParam
end
get '/users' do
  # ...
end
```

### From Inline Response Models to Reusable Responses

Before:
```ruby
desc 'Get item',
     success: { code: 200, message: 'Success' },
     failure: [
       { code: 404, message: 'Not found' },
       { code: 401, message: 'Unauthorized' }
     ]
```

After:
```ruby
desc 'Get item',
     success: { code: 200, message: 'Success' },
     failure: [
       { code: 404, model: :NotFoundResponse },
       { code: 401, model: :UnauthorizedResponse }
     ]
```

## Troubleshooting

### Component Not Found Errors

If you see errors like "Parameter component 'PageParam' not found":

1. Ensure the component class is defined before it's referenced
2. Check that the component file is being loaded (add to initializer)
3. Verify the component name matches exactly (case-sensitive)

### Name Collision Warnings

If you see warnings about component name collisions:

```
[grape-swagger] Component name collision: PageParam already registered by Api::V1::PageParam,
now being overwritten by Api::V2::PageParam. Use `component_name 'UniqueNameHere'` to resolve.
```

Use the `component_name` method to give each component a unique name:

```ruby
class Api::V1::PageParam < GrapeSwagger::ReusableParameter
  component_name 'V1PageParam'
  # ...
end
```

### Components Not Appearing in OpenAPI Doc

If your components aren't showing up in the generated OpenAPI document:

1. Verify the component files are being loaded
2. Check that the class inherits from the correct base class
3. Ensure `add_swagger_documentation` is called after components are loaded
4. Look for Ruby syntax errors in component definitions

## Implementation Details

### Auto-Registration

Components auto-register using Ruby's `inherited` hook combined with `TracePoint`:

```ruby
class ReusableParameter
  def self.inherited(subclass)
    super
    TracePoint.new(:end) do |tp|
      if tp.self == subclass
        ComponentsRegistry.register_parameter(subclass)
        tp.disable
      end
    end.enable
  end
end
```

This ensures the component is fully defined before registration.

### Components Registry

All components are stored in `GrapeSwagger::ComponentsRegistry`:

```ruby
ComponentsRegistry.parameters  # => Hash of parameter name => class
ComponentsRegistry.responses   # => Hash of response name => class
ComponentsRegistry.headers     # => Hash of header name => class
ComponentsRegistry.to_openapi  # => OpenAPI components hash
```

### Integration with ComponentsBuilder

The `ComponentsBuilder` automatically merges registered components into the OpenAPI document:

1. Registered components are converted to OpenAPI format
2. Manually-specified components take precedence
3. All components are validated and included in the output

## See Also

- [ComponentsObject.md](ComponentsObject.md) - Components Object specification
- [ParameterObject.md](ParameterObject.md) - Parameter Object specification
- [ResponseObject.md](ResponseObject.md) - Response Object specification
- [HeaderObject.md](HeaderObject.md) - Header Object specification

## Tests

- `spec/grape-swagger/components_registry_spec.rb`
- `spec/grape-swagger/reusable_parameter_spec.rb`
- `spec/grape-swagger/reusable_response_spec.rb`
- `spec/grape-swagger/reusable_header_spec.rb`
- `spec/grape-swagger/endpoint/params_extensions_spec.rb`
- `spec/grape-swagger/endpoint/response_refs_spec.rb`
- `spec/integration/reusable_components_spec.rb`

## Implementation

- `lib/grape-swagger/components_registry.rb`
- `lib/grape-swagger/reusable_parameter.rb`
- `lib/grape-swagger/reusable_response.rb`
- `lib/grape-swagger/reusable_header.rb`
- `lib/grape-swagger/endpoint/params_extensions.rb`
- `lib/grape-swagger/openapi/components_builder.rb`
