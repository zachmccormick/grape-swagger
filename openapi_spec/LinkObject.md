# Link Object

The Link Object represents a possible design-time link for a response. Links enable API traversal by describing relationships between operations.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `operationRef` | string | No | ✅ | Relative/absolute reference to operation. Mutually exclusive with `operationId` |
| `operationId` | string | No | ✅ | Name of existing operation. Mutually exclusive with `operationRef` |
| `parameters` | Map[string, any \| expression] | No | ✅ | Parameters to pass to linked operation. Supports runtime expressions |
| `requestBody` | any \| expression | No | ✅ | Request body for linked operation. Supports runtime expressions |
| `description` | string | No | ✅ | Link description. CommonMark syntax MAY be used for rich text |
| `server` | [Server Object](ServerObject.md) | No | ✅ | Alternative server for target operation |

**Notes:**
- `operationRef` and `operationId` are mutually exclusive per the OpenAPI specification
- Link Objects MAY be extended with Specification Extensions (fields starting with `x-`)
- CommonMark syntax MAY be used in the `description` field for rich text representation

## Status

✅ **Fully Implemented** (OpenAPI 3.1.0 only)

Links are fully supported in grape-swagger for OpenAPI 3.1.0 specifications. All Link Object fields and runtime expressions are implemented.

## Use Case

Links describe how responses from one operation can be used as input to another:

```json
{
  "paths": {
    "/users/{id}": {
      "get": {
        "operationId": "getUser",
        "responses": {
          "200": {
            "description": "User found",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/User"
                }
              }
            },
            "links": {
              "GetUserOrders": {
                "operationId": "getOrdersByUser",
                "parameters": {
                  "userId": "$response.body#/id"
                },
                "description": "Get orders for this user"
              },
              "GetUserProfile": {
                "operationRef": "#/paths/~1users~1{id}~1profile/get",
                "parameters": {
                  "id": "$response.body#/id"
                }
              }
            }
          }
        }
      }
    }
  }
}
```

## Runtime Expressions

Links use runtime expressions to reference values:

| Expression | Description |
|-----------|-------------|
| `$url` | Full request URL |
| `$method` | HTTP method |
| `$statusCode` | Response status code |
| `$request.path.name` | Path parameter |
| `$request.query.name` | Query parameter |
| `$request.header.name` | Header value |
| `$request.body#/pointer` | Request body JSON pointer |
| `$response.body#/pointer` | Response body JSON pointer |
| `$response.header.name` | Response header value |

## Usage

Links are specified per response status code in the `desc` block:

```ruby
desc 'Create user',
     success: { code: 201, message: 'User created' },
     links: {
       201 => {
         GetUserById: {
           operation_id: 'getUser',
           parameters: { userId: '$response.body#/id' },
           description: 'Retrieve the created user'
         },
         GetUserOrders: {
           operation_id: 'getOrdersByUser',
           parameters: { userId: '$response.body#/id' },
           description: 'Get orders for this user'
         }
       }
     }
post '/users' do
  # ...
end

desc 'Get user by ID',
     operationId: 'getUser'
params do
  requires :id, type: Integer
end
get '/users/:id' do
  # ...
end
```

### Using operationRef

```ruby
links: {
  200 => {
    GetUserProfile: {
      operation_ref: '#/paths/~1users~1{id}~1profile/get',
      parameters: { id: '$response.body#/id' }
    }
  }
}
```

### Custom Server

```ruby
links: {
  201 => {
    GetUserById: {
      operation_id: 'getUser',
      parameters: { userId: '$response.body#/id' },
      server: {
        url: 'https://api.example.com',
        description: 'Production server'
      }
    }
  }
}
```
