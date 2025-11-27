# Paths Object

Holds the relative paths to the individual endpoints and their operations.

## Patterned Fields

| Field Pattern | Type | Required | Supported | Notes |
|---------------|------|----------|-----------|-------|
| `/{path}` | [Path Item Object](PathItemObject.md) | No | :white_check_mark: | Auto-generated from Grape routes |
| `^x-` | Any | No | :white_check_mark: | [Specification Extensions](https://spec.openapis.org/oas/v3.1.0#specification-extensions) |

## Usage

Paths are automatically generated from your Grape API routes:

```ruby
class MyAPI < Grape::API
  resource :users do
    get do
      # GET /users
    end

    post do
      # POST /users
    end

    route_param :id do
      get do
        # GET /users/{id}
      end
    end
  end
end
```

## Output Example

```json
{
  "paths": {
    "/users": {
      "get": { ... },
      "post": { ... }
    },
    "/users/{id}": {
      "get": { ... }
    }
  }
}
```

## Path Templating

- Path parameters use `{paramName}` syntax
- Grape's `:param` syntax is converted to `{param}`
- Path segments are URL-encoded as needed

## Tests

- `spec/lib/path_string_spec.rb`
- Most integration specs test path generation

## Implementation

- `lib/grape-swagger/doc_methods/path_string.rb`
- `lib/grape-swagger/endpoint.rb`

## Specification Notes

### Path Format Requirements
- Paths MUST begin with a forward slash `/`
- Paths are appended (without relative URL resolution) to the expanded URL from the Server Object's `url` field
- Path templating is permitted using curly braces `{paramName}`

### Path Matching Rules
- Concrete (non-templated) paths match before templated paths
  - Example: `/pets/mine` matches before `/pets/{petId}`
- Templated paths with identical hierarchy but different template names are not allowed
  - Example: `/pets/{petId}` and `/pets/{name}` cannot both exist
- Ambiguous matching is left to tooling discretion

### ACL Constraints
- The Paths Object MAY be empty due to Access Control List (ACL) constraints

### Specification Extensions
- The Paths Object MAY be extended with [Specification Extensions](https://spec.openapis.org/oas/v3.1.0#specification-extensions) using the `^x-` pattern
