# PR 13: Callbacks & Links

## Overview

CallbackBuilder creates operation-level `callbacks` objects for OpenAPI 3.1.0, allowing APIs to describe asynchronous, out-of-band requests triggered by the original request. LinkBuilder creates response-level `links` objects that describe relationships between operations using runtime expressions and parameter mapping.

Both features are exclusive to OpenAPI 3.1.0 and return nil for Swagger 2.0.

## Key Components

### CallbackBuilder (`lib/grape-swagger/openapi/callback_builder.rb`)

Class method `.build(callback_definitions, version)` constructs the callbacks object:

- **build**: Entry point; iterates callback definitions, returns nil for empty/nil/Swagger 2.0 input
- **build_callback**: Maps each callback to its URL expression key (supports runtime expressions like `{$request.body#/callbackUrl}`)
- **build_operation**: Wraps the callback under its HTTP method (defaults to POST; supports PUT, DELETE, etc.)
- **build_operation_object**: Builds summary, description, requestBody, and responses
- **build_request_body**: Constructs requestBody with content type (defaults to `application/json`), required flag (defaults to true)
- **build_responses**: Builds response objects keyed by status code with optional schemas
- **build_schema**: Handles both `$ref` references and inline schema definitions

#### Runtime Expressions

Callback URLs support OpenAPI runtime expressions:
- `{$url}` - the URL of the original request
- `{$method}` - the HTTP method of the original request
- `{$request.body#/callbackUrl}` - JSON pointer into request body
- `{$request.query.param}` - query parameter value
- `{$request.header.X-Header}` - request header value
- `{$response.body#/pointer}` - JSON pointer into response body
- Multiple expressions can be combined in a single URL

### LinkBuilder (`lib/grape-swagger/openapi/link_builder.rb`)

Class method `.build(link_definitions, version)` constructs the links object:

- **build**: Entry point; iterates link definitions, returns nil for empty/nil/Swagger 2.0 input
- **build_link**: Constructs individual link objects with operationId/operationRef, parameters, requestBody, description, and server
- Nil values are compacted from the output

#### Link Properties

- **operationId**: References another operation by its operationId
- **operationRef**: References another operation by JSON pointer (e.g., `#/paths/~1users~1{id}/get`)
- **parameters**: Maps link parameters to runtime expressions or static values
- **requestBody**: Maps request body fields to runtime expressions
- **description**: Human-readable description of the link
- **server**: Override server for the linked operation

### Integration Points

- **endpoint.rb**: After building the method object, checks `route.options[:callbacks]` and calls `CallbackBuilder.build`; iterates `route.options[:links]` by status code and calls `LinkBuilder.build` for each, attaching to the corresponding response
- Callbacks appear at the operation level (alongside parameters, responses, etc.)
- Links appear inside individual response objects

## Configuration Example

### Callbacks

```ruby
desc 'Create subscription',
  callbacks: {
    onEvent: {
      url: '{$request.body#/callbackUrl}',
      method: :post,
      summary: 'Event notification',
      request: {
        schema: { '$ref' => '#/components/schemas/Event' }
      },
      responses: {
        200 => { description: 'Processed' }
      }
    }
  }
```

### Links

```ruby
desc 'Create user',
  links: {
    201 => {
      GetUserById: {
        operation_id: 'getUser',
        description: 'Retrieve the created user',
        parameters: {
          userId: '$response.body#/id'
        }
      }
    }
  }
```

## Test Coverage

- `spec/grape-swagger/openapi/callback_builder_spec.rb` - Unit tests for callback definition structure, runtime expressions, HTTP methods, requestBody, responses, and edge cases
- `spec/grape-swagger/openapi/link_builder_spec.rb` - Unit tests for link definition structure, operationId/operationRef, parameter mapping, runtime expressions, and edge cases
- `spec/grape-swagger/openapi/callbacks_links_integration_spec.rb` - Integration test verifying callbacks and links flow through endpoint.rb into the assembled operation/response objects
