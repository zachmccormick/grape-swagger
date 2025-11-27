# Schema Object

The Schema Object allows the definition of input and output data types. Based on JSON Schema Draft 2020-12 with OpenAPI-specific extensions.

## Core JSON Schema Fields

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `type` | string \| [string] | :white_check_mark: | Data type(s) |
| `format` | string | :white_check_mark: | Type format |
| `title` | string | :x: | Schema title |
| `description` | string | :white_check_mark: | From `desc:` |
| `default` | any | :white_check_mark: | Default value |
| `enum` | [any] | :white_check_mark: | Enumerated values |
| `const` | any | :white_check_mark: | Constant value |
| `examples` | [any] | :construction: | Example values (partial) |

## Object Keywords

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `properties` | Map[string, Schema] | :white_check_mark: | Object properties |
| `required` | [string] | :white_check_mark: | Required properties |
| `additionalProperties` | boolean \| Schema | :white_check_mark: | Extra properties |
| `minProperties` | integer | :x: | Min properties |
| `maxProperties` | integer | :x: | Max properties |
| `patternProperties` | Map[string, Schema] | :x: | Pattern matching |
| `propertyNames` | Schema | :x: | Property name schema |
| `dependentRequired` | Map[string, [string]] | :x: | Conditional required |

## Array Keywords

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `items` | Schema | :white_check_mark: | Array item schema |
| `prefixItems` | [Schema] | :x: | Tuple validation |
| `minItems` | integer | :x: | Minimum items |
| `maxItems` | integer | :x: | Maximum items |
| `uniqueItems` | boolean | :x: | Unique items only |
| `contains` | Schema | :x: | At least one match |
| `minContains` | integer | :x: | Min matching contains |
| `maxContains` | integer | :x: | Max matching contains |

## String Keywords

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `minLength` | integer | :white_check_mark: | Minimum length (tested) |
| `maxLength` | integer | :white_check_mark: | Maximum length (tested) |
| `pattern` | string | :white_check_mark: | Regex pattern |

## Numeric Keywords

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `minimum` | number | :white_check_mark: | From `values: X..Y` |
| `maximum` | number | :white_check_mark: | From `values: X..Y` |
| `exclusiveMinimum` | number | :x: | Exclusive min |
| `exclusiveMaximum` | number | :x: | Exclusive max |
| `multipleOf` | number | :x: | Multiple validation |

## Schema Composition

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `allOf` | [Schema] | :white_check_mark: | All schemas must match |
| `oneOf` | [Schema] | :white_check_mark: | Exactly one must match |
| `anyOf` | [Schema] | :white_check_mark: | At least one must match |
| `not` | Schema | :x: | Must not match |

## Conditional Keywords

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `if` | Schema | :white_check_mark: | Conditional validation |
| `then` | Schema | :white_check_mark: | Applied when if matches |
| `else` | Schema | :white_check_mark: | Applied when if fails |
| `dependentSchemas` | Map[string, Schema] | :white_check_mark: | Property-dependent schemas |

## Unevaluated Keywords

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `unevaluatedItems` | Schema \| boolean | :x: | Unevaluated array items |
| `unevaluatedProperties` | Schema \| boolean | :x: | Unevaluated object props |

## JSON Schema Metadata Keywords

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `$id` | string | :x: | Schema identifier |
| `$schema` | string | :x: | Meta-schema URI |
| `$ref` | string | :white_check_mark: | Schema reference |
| `$anchor` | string | :x: | Fragment identifier |
| `$dynamicAnchor` | string | :x: | Dynamic fragment |
| `$dynamicRef` | string | :x: | Dynamic reference |
| `$defs` | Map[string, Schema] | :x: | Local definitions |
| `$comment` | string | :x: | Internal comment |
| `$vocabulary` | Map[string, boolean] | :x: | Vocabulary declarations |

## Content Keywords (OpenAPI 3.1.0)

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `contentMediaType` | string | :white_check_mark: | Media type hint |
| `contentEncoding` | string | :white_check_mark: | Base64 encoding |
| `contentSchema` | Schema | :x: | Decoded content schema |

## OpenAPI Extensions

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| `discriminator` | [Discriminator Object](DiscriminatorObject.md) | :white_check_mark: | Polymorphism |
| `xml` | XML Object | :x: | XML representation |
| `externalDocs` | External Documentation Object | :x: | External docs |
| `deprecated` | boolean | :white_check_mark: | Deprecation flag |
| `nullable` | boolean | :white_check_mark: | Nullable (3.0 style) |
| `readOnly` | boolean | :white_check_mark: | Read-only property |
| `writeOnly` | boolean | :white_check_mark: | Write-only property |

## OpenAPI 3.1.0 Specific

| Field | Type | Supported | Notes |
|-------|------|-----------|-------|
| Type arrays | [string] | :white_check_mark: | `["string", "null"]` |

## Usage

### From Grape Params

```ruby
params do
  requires :name, type: String, desc: 'User name'
  requires :age, type: Integer, values: 18..120, desc: 'Age'
  optional :email, type: String, desc: 'Email address'
  optional :role, type: String, values: %w[admin user guest], default: 'user'
  optional :tags, type: Array[String], desc: 'User tags'
end
```

### From Grape Entity

```ruby
class UserEntity < Grape::Entity
  expose :id, documentation: { type: Integer, desc: 'User ID' }
  expose :name, documentation: { type: String, desc: 'Full name' }
  expose :email, documentation: { type: String, format: 'email' }
  expose :role, documentation: { type: String, values: %w[admin user] }
  expose :avatar_url, documentation: { type: String, nullable: true }
  expose :created_at, documentation: { type: DateTime }
  expose :password, documentation: { type: String, write_only: true }
  expose :internal_id, documentation: { type: String, read_only: true }
end
```

## Output Example

```json
{
  "User": {
    "type": "object",
    "properties": {
      "id": {
        "type": "integer",
        "format": "int32",
        "description": "User ID"
      },
      "name": {
        "type": "string",
        "description": "Full name"
      },
      "email": {
        "type": "string",
        "format": "email"
      },
      "role": {
        "type": "string",
        "enum": ["admin", "user"]
      },
      "avatar_url": {
        "type": ["string", "null"]
      },
      "created_at": {
        "type": "string",
        "format": "date-time"
      },
      "password": {
        "type": "string",
        "writeOnly": true
      },
      "internal_id": {
        "type": "string",
        "readOnly": true
      }
    },
    "required": ["id", "name", "email", "role", "created_at"]
  }
}
```

## Type Mapping

| Grape/Ruby Type | OpenAPI type | format |
|-----------------|--------------|--------|
| String | string | - |
| Integer | integer | int32 |
| Float | number | float |
| BigDecimal | number | double |
| Boolean | boolean | - |
| Date | string | date |
| DateTime | string | date-time |
| Time | string | date-time |
| File | string | binary |
| Array[T] | array | items: T |
| Hash | object | - |
| Symbol | string | - |

## Tests

- `spec/lib/data_type_spec.rb`
- `spec/grape-swagger/openapi/nullable_type_handler_spec.rb`
- `spec/grape-swagger/openapi/type_mapper_spec.rb`
- `spec/grape-swagger/openapi/polymorphic_schema_builder_spec.rb`
- `spec/grape-swagger/openapi/conditional_schema_builder_spec.rb`
- `spec/grape-swagger/openapi/advanced_features_spec.rb` (readOnly/writeOnly)

## Implementation

- `lib/grape-swagger/doc_methods/data_type.rb`
- `lib/grape-swagger/openapi/type_mapper.rb`
- `lib/grape-swagger/openapi/nullable_type_handler.rb`
- `lib/grape-swagger/openapi/schema_resolver.rb`
- `lib/grape-swagger/openapi/conditional_schema_builder.rb`

## TODO

### Not Yet Implemented
- [ ] Add `minItems`/`maxItems` support
- [ ] Add `uniqueItems` support
- [ ] Add `exclusiveMinimum`/`exclusiveMaximum` support
- [ ] Add `not` composition support
- [ ] Add `minProperties`/`maxProperties` support
- [ ] Add `patternProperties` support
- [ ] Add `propertyNames` support

### Low Priority (Advanced/Rare)
- [ ] Add `$id`/`$anchor` support
- [ ] Add `$defs` support for local schema definitions
- [ ] Add `unevaluatedItems`/`unevaluatedProperties` support
- [ ] Add `prefixItems` support for tuple validation
- [ ] Add `contains`/`minContains`/`maxContains` support
- [ ] Add `contentSchema` support
