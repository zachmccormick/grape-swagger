# Path Item Object

Describes the operations available on a single path.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `$ref` | string | No | :x: | Allows referencing a path item definition. Note: behavior of `$ref` with adjacent properties may change in future OpenAPI versions |
| `summary` | string | No | :x: | Optional summary intended to apply to all operations in this path |
| `description` | string | No | :x: | Optional description (CommonMark syntax). Applies to all operations in this path |
| `get` | [Operation Object](OperationObject.md) | No | :white_check_mark: | Defines a GET operation on this path |
| `put` | [Operation Object](OperationObject.md) | No | :white_check_mark: | Defines a PUT operation on this path |
| `post` | [Operation Object](OperationObject.md) | No | :white_check_mark: | Defines a POST operation on this path |
| `delete` | [Operation Object](OperationObject.md) | No | :white_check_mark: | Defines a DELETE operation on this path |
| `options` | [Operation Object](OperationObject.md) | No | :white_check_mark: | Defines an OPTIONS operation on this path |
| `head` | [Operation Object](OperationObject.md) | No | :white_check_mark: | Defines a HEAD operation on this path |
| `patch` | [Operation Object](OperationObject.md) | No | :white_check_mark: | Defines a PATCH operation on this path |
| `trace` | [Operation Object](OperationObject.md) | No | :x: | Defines a TRACE operation on this path (rarely used) |
| `servers` | [[Server Object](ServerObject.md)] | No | :x: | Alternative server array to service all operations in this path. Overrides the top-level servers array |
| `parameters` | [[Parameter Object](ParameterObject.md) \| [Reference Object](ReferenceObject.md)] | No | :x: | List of parameters common to all operations in this path. Can be overridden at operation level but not removed. Parameters are unique by combination of `name` and `in` |

## Specification Notes

### Path-Level Parameters
Parameters defined at the path level apply to all operations within that path. These parameters:
- Can be overridden at the operation level
- Cannot be removed at the operation level (only overridden)
- Must be unique by the combination of `name` and `in` fields
- Are useful for path parameters like IDs that apply to all operations

### Empty Path Items
A Path Item Object may be empty due to Access Control List (ACL) constraints. This is permitted by the specification.

### Reference Behavior
When using `$ref` at the path level, the behavior when combined with other properties (like operations) is implementation-defined and may change in future OpenAPI versions.

### Servers Override
The `servers` array at the path level overrides the top-level `servers` array for all operations in this path.

## Usage

Operations are automatically generated from Grape route definitions:

```ruby
resource :pets do
  desc 'List all pets'
  get do
    # Creates GET /pets
  end

  desc 'Create a pet'
  post do
    # Creates POST /pets
  end

  route_param :id do
    desc 'Get a pet'
    get do
      # Creates GET /pets/{id}
    end

    desc 'Update a pet'
    put do
      # Creates PUT /pets/{id}
    end

    desc 'Delete a pet'
    delete do
      # Creates DELETE /pets/{id}
    end
  end
end
```

## Output Example

```json
{
  "paths": {
    "/pets/{id}": {
      "get": {
        "summary": "Get a pet",
        "operationId": "getPetsId",
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": { "type": "integer" }
          }
        ],
        "responses": { ... }
      },
      "put": { ... },
      "delete": { ... }
    }
  }
}
```

## Tests

- `spec/swagger_v2/api_swagger_v2_spec.rb`
- `spec/openapi_v3_1/` integration specs

## Implementation

- `lib/grape-swagger/endpoint.rb`

## Current Limitations

### Unsupported Fields

1. **`$ref`** - Path item references are not supported. All path items must be defined inline.

2. **`summary`** - Path-level summaries are not supported. Summaries must be defined at the operation level using `desc`.

3. **`description`** - Path-level descriptions are not supported. Descriptions must be defined at the operation level using `desc` or `detail`.

4. **`servers`** - Path-level server overrides are not supported. All paths use the top-level servers configuration.

5. **`parameters`** - Path-level parameters are not supported. All parameters must be defined at the operation level, even if they apply to multiple operations on the same path.

6. **`trace`** - The TRACE HTTP method is not supported by Grape, so trace operations cannot be generated.

### Workarounds

- **Path-level parameters**: Define the same parameter on each operation. Grape's `route_param` creates path parameters, but they are added to each operation individually rather than at the path level.

- **Path-level summary/description**: Use operation-level `desc` and `detail` on each endpoint. Group related operations using the same tag.

## TODO

- [ ] Investigate supporting path-level `parameters` to reduce duplication for shared path/query params
- [ ] Consider path-level `summary` and `description` for documentation organization
- [ ] Evaluate path-level `servers` support for multi-environment documentation
