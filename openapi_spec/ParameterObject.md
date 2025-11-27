# Parameter Object

Describes a single operation parameter.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `name` | string | Yes | :white_check_mark: | From Grape param name |
| `in` | string | Yes | :white_check_mark: | query, header, path, cookie |
| `description` | string | No | :white_check_mark: | From `desc:` option |
| `required` | boolean | No | :white_check_mark: | From `requires`/`optional`; auto-true for path params |
| `deprecated` | boolean | No | :white_check_mark: | From `documentation: { deprecated: true }` |
| `allowEmptyValue` | boolean | No | :white_check_mark: | From `allow_blank:` |
| `style` | string | No | :white_check_mark: | Serialization style; defaults per location |
| `explode` | boolean | No | :white_check_mark: | Array/object expansion; auto-set based on style |
| `allowReserved` | boolean | No | :white_check_mark: | From `documentation: { allowReserved: true }` |
| `schema` | [Schema Object](SchemaObject.md) | No* | :white_check_mark: | Required unless using `content` |
| `example` | any | No | :white_check_mark: | Single example value |
| `examples` | Map[string, [Example Object](ExampleObject.md)] | No | :x: | Multiple examples not implemented |
| `content` | Map[string, [Media Type Object](MediaTypeObject.md)] | No* | :x: | Alternative to `schema`; not implemented |

**Note:** Either `schema` or `content` MUST be provided, but not both. grape-swagger only supports the `schema` approach.

## Parameter Locations (`in`)

| Location | Supported | Notes |
|----------|-----------|-------|
| `query` | :white_check_mark: | Query string parameters |
| `path` | :white_check_mark: | URL path parameters (auto-detected from routes) |
| `header` | :white_check_mark: | HTTP header parameters |
| `cookie` | :white_check_mark: | Cookie parameters via `documentation: { in: 'cookie' }` |

**Reserved Headers:** The OpenAPI specification states that `Accept`, `Content-Type`, and `Authorization` headers are ignored when `in: "header"` because they are handled through other OpenAPI constructs.

## Usage

```ruby
params do
  # Path parameter (auto-detected from route)
  requires :id, type: Integer, desc: 'User ID'

  # Query parameters
  optional :name, type: String, desc: 'Filter by name'
  optional :status, type: String, values: %w[active inactive], desc: 'Filter by status'
  optional :limit, type: Integer, values: 1..100, default: 20, desc: 'Results per page'

  # Array parameters
  optional :tags, type: Array[String], desc: 'Filter by tags'

  # Allow empty values
  optional :search, type: String, allow_blank: true, desc: 'Search query'

  # Deprecated parameter
  optional :legacy_id, type: Integer, documentation: { deprecated: true }, desc: 'Use id instead'

  # Cookie parameter
  optional :session_token, type: String, documentation: { in: 'cookie' }, desc: 'Session token'

  # Allow reserved characters (RFC3986)
  optional :filter, type: String, documentation: { allowReserved: true }, desc: 'Filter expression'
end
get ':id' do
  # ...
end
```

## Serialization Styles

The `style` field defines how parameters are serialized. grape-swagger sets appropriate defaults:

| Location | Default Style | Description |
|----------|--------------|-------------|
| `query` | `form` | Form-style parameters (e.g., `?tags=red&tags=blue`) |
| `path` | `simple` | Simple comma-separated (e.g., `/users/1,2,3`) |
| `header` | `simple` | Simple comma-separated |
| `cookie` | `form` | Form-style serialization |

The `explode` field controls array/object serialization:
- For `style: form` → `explode: true` (default): `?tags=red&tags=blue`
- For `style: simple` → `explode: false` (default): comma-separated values

## Output Example (OpenAPI 3.1.0)

```json
{
  "parameters": [
    {
      "name": "id",
      "in": "path",
      "description": "User ID",
      "required": true,
      "schema": {
        "type": "integer",
        "format": "int32"
      },
      "style": "simple"
    },
    {
      "name": "status",
      "in": "query",
      "description": "Filter by status",
      "required": false,
      "schema": {
        "type": "string",
        "enum": ["active", "inactive"]
      },
      "style": "form"
    },
    {
      "name": "tags",
      "in": "query",
      "description": "Filter by tags",
      "required": false,
      "schema": {
        "type": "array",
        "items": { "type": "string" }
      },
      "style": "form",
      "explode": true
    },
    {
      "name": "legacy_id",
      "in": "query",
      "description": "Use id instead",
      "required": false,
      "deprecated": true,
      "schema": {
        "type": "integer",
        "format": "int32"
      },
      "style": "form"
    },
    {
      "name": "session_token",
      "in": "cookie",
      "description": "Session token",
      "required": false,
      "schema": {
        "type": "string"
      },
      "style": "form"
    }
  ]
}
```

## Grape Type Mapping

| Grape Type | OpenAPI Type | Format |
|------------|--------------|--------|
| String | string | - |
| Integer | integer | int32 |
| Float | number | float |
| Boolean | boolean | - |
| Date | string | date |
| DateTime | string | date-time |
| Array[T] | array | items: T |
| File | string | binary |

## Tests

- `spec/lib/parse_params_spec.rb` - Core parameter parsing
- `spec/swagger_v2/param_values_spec.rb` - Swagger 2.0 compatibility
- `spec/grape-swagger/openapi/parameter_schema_wrapper_spec.rb` - OpenAPI 3.1.0 schema wrapping
- `spec/grape-swagger/openapi/advanced_features_spec.rb` - Cookie, deprecated, allowReserved

## Implementation

- `lib/grape-swagger/doc_methods/parse_params.rb` - Parameter parsing and extraction
- `lib/grape-swagger/openapi/parameter_schema_wrapper.rb` - OpenAPI 3.1.0 parameter wrapping

## Specification Compliance

### Implemented Fields (11/13)

All fields from the OpenAPI 3.1.0 Parameter Object specification are supported except:

- ✅ `name` - Required, from Grape parameter name
- ✅ `in` - Required, supports query, path, header, cookie
- ✅ `description` - From `desc:` option
- ✅ `required` - From `requires`/`optional`, auto-true for path parameters
- ✅ `deprecated` - From `documentation: { deprecated: true }`
- ✅ `allowEmptyValue` - From `allow_blank: true`
- ✅ `style` - Auto-set based on location, overridable
- ✅ `explode` - Auto-set based on style for arrays/objects
- ✅ `allowReserved` - From `documentation: { allowReserved: true }`
- ✅ `schema` - Schema Object, wraps type/format/etc
- ✅ `example` - Single example value
- ❌ `examples` - Map of Example Objects (not implemented)
- ❌ `content` - Media Type Object map (not implemented)

### Not Implemented

- **`examples` (plural)**: Multiple named examples. Use singular `example` instead.
- **`content`**: Alternative to `schema` for complex media types. grape-swagger only supports the `schema` approach, which covers the vast majority of use cases.

## Notes

### Schema vs Content

The OpenAPI specification requires either `schema` OR `content`, but not both:
- **`schema`**: Standard approach for most parameters (supported)
- **`content`**: Advanced approach for parameters with complex media types like `application/json` (not implemented)

grape-swagger always uses the `schema` approach, which is sufficient for typical API parameter needs.

### Path Parameter Requirements

Per the OpenAPI spec, path parameters MUST have `required: true`. grape-swagger enforces this automatically for any parameter detected in the path template.
