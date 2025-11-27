# Discriminator Object

A mapping tool designed to guide the selection among multiple schemas when dealing with polymorphic data structures. Used with composition keywords (oneOf, anyOf, allOf) to aid in serialization, deserialization, and validation when request bodies or response payloads may be one of a number of different schemas.

## Specification Reference

Section 4.8.25 of OpenAPI 3.1.0 specification.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `propertyName` | string | Yes | :white_check_mark: | The name of the property in the payload that will determine which schema should be applied |
| `mapping` | Map[string, string] | No | :white_check_mark: | An enumeration mapping of discriminator values to schema names or references, allowing explicit association between possible values and their corresponding schemas |

**Note:** This object may be extended with Specification Extensions (fields starting with `x-`).

## Usage

### With Grape Entity

```ruby
class AnimalEntity < Grape::Entity
  expose :name, documentation: { type: String }
  expose :animal_type, documentation: { type: String }
end

class DogEntity < AnimalEntity
  expose :breed, documentation: { type: String }
  expose :bark_volume, documentation: { type: Integer }
end

class CatEntity < AnimalEntity
  expose :color, documentation: { type: String }
  expose :indoor, documentation: { type: Boolean }
end

# Using polymorphic option
desc 'Get any animal',
     success: {
       model: AnimalEntity,
       polymorphic: {
         discriminator_property: :animal_type,
         mapping: {
           'dog' => DogEntity,
           'cat' => CatEntity
         }
       }
     }
get '/animals/:id' do
  # ...
end
```

### Using oneOf

```ruby
desc 'Create animal',
     success: {
       oneOf: [DogEntity, CatEntity],
       discriminator: {
         propertyName: 'animal_type',
         mapping: {
           'dog' => '#/components/schemas/Dog',
           'cat' => '#/components/schemas/Cat'
         }
       }
     }
post '/animals' do
  # ...
end
```

## Output Example

```json
{
  "components": {
    "schemas": {
      "Animal": {
        "oneOf": [
          { "$ref": "#/components/schemas/Dog" },
          { "$ref": "#/components/schemas/Cat" }
        ],
        "discriminator": {
          "propertyName": "animal_type",
          "mapping": {
            "dog": "#/components/schemas/Dog",
            "cat": "#/components/schemas/Cat"
          }
        }
      },
      "Dog": {
        "allOf": [
          { "$ref": "#/components/schemas/AnimalBase" },
          {
            "type": "object",
            "properties": {
              "breed": { "type": "string" },
              "bark_volume": { "type": "integer" }
            }
          }
        ]
      },
      "Cat": {
        "allOf": [
          { "$ref": "#/components/schemas/AnimalBase" },
          {
            "type": "object",
            "properties": {
              "color": { "type": "string" },
              "indoor": { "type": "boolean" }
            }
          }
        ]
      }
    }
  }
}
```

## Tests

- `spec/grape-swagger/openapi/discriminator_builder_spec.rb` - Discriminator object construction
- `spec/grape-swagger/openapi/polymorphic_schema_builder_spec.rb` - Schema composition with discriminators
- `spec/swagger_v2/inheritance_and_discriminator_spec.rb` - Swagger 2.0 discriminator support

## Implementation

- `lib/grape-swagger/openapi/discriminator_builder.rb` - Main discriminator builder
- `lib/grape-swagger/openapi/polymorphic_schema_builder.rb` - Polymorphic schema handling
- `lib/grape-swagger/openapi/discriminator_transformer.rb` - Discriminator transformations

## Notes

### propertyName Field
- **REQUIRED** in OpenAPI 3.1.0
- The property must exist in all referenced schemas
- Specifies which property in the payload determines the schema to apply
- Used by deserializers and code generators to identify the correct type

### mapping Field
- **Optional** in OpenAPI 3.1.0
- Maps discriminator values to schema names or references
- Without `mapping`: the property value must exactly match the schema name (case-sensitive)
- With `mapping`: you can use custom values that map to schemas
- Values can be:
  - Simple schema names (converted to `#/components/schemas/{name}`)
  - Local references (e.g., `#/components/schemas/Dog`)
  - External references (e.g., `https://example.com/schemas/Cat`)

### Use Cases
- Polymorphic request bodies or responses (oneOf, anyOf, allOf)
- Inheritance hierarchies with type discrimination
- API versioning with type selection
- Code generation tools for strongly-typed languages
- Serialization/deserialization with type hints

### Swagger 2.0 Compatibility
- Swagger 2.0 only supports `discriminator` as a string (the property name)
- The `mapping` field is not available in Swagger 2.0
- grape-swagger automatically handles version differences
