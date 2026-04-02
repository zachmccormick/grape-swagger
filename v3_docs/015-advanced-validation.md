# PR 15: Advanced Schema Validation

## Overview

Adds three advanced JSON Schema validation handlers for OpenAPI 3.1.0:
conditional schemas (if/then/else), dependent schemas/required, and
additional/unevaluated/pattern properties. Each handler is version-aware,
producing native output for 3.1.0 and gracefully degrading for Swagger 2.0.

## Components

### ConditionalSchemaBuilder

Handles `if`/`then`/`else` conditional schema keywords (JSON Schema 2020-12).

- **OpenAPI 3.1.0**: Preserves conditional keywords as-is, including nested
  conditionals inside `allOf`, `oneOf`, and `anyOf` composition keywords
- **Swagger 2.0**: Strips all conditional keywords (not supported in the spec)
- Processes nested conditional schemas recursively

### DependentSchemaHandler

Transforms legacy `dependencies` keyword into the split 3.1.0 format.

- **Array dependencies** (property presence requires other properties) become
  `dependentRequired`
- **Schema dependencies** (property presence requires schema constraints) become
  `dependentSchemas`
- **Mixed dependencies** are split into both keywords automatically
- **Swagger 2.0**: Leaves `dependencies` untouched (natively supported)
- Processes nested schemas recursively (properties, composition keywords,
  dependentSchemas)
- Deep-duplicates input to guarantee immutability

### AdditionalPropertiesHandler

Manages `additionalProperties`, `unevaluatedProperties`, and `patternProperties`.

- **`additionalProperties`**: Boolean or schema value, supported in both versions
- **`unevaluatedProperties`**: Boolean or schema value, OpenAPI 3.1.0 only
  (silently ignored for Swagger 2.0)
- **`patternProperties`**: Native keyword for 3.1.0, emitted as
  `x-patternProperties` extension for Swagger 2.0
- Only applied to object-type schemas (non-object types are returned unchanged)
- Deep-duplicates input to guarantee immutability

## Pipeline Integration

All three handlers are wired into `SchemaResolver#apply_transformations`,
running after the existing `NullableTypeHandler` and `BinaryDataEncoder`
transforms.

## Files

| File | Purpose |
|------|---------|
| `lib/grape-swagger/openapi/conditional_schema_builder.rb` | if/then/else handler |
| `lib/grape-swagger/openapi/dependent_schema_handler.rb` | dependentSchemas/Required handler |
| `lib/grape-swagger/openapi/additional_properties_handler.rb` | additionalProperties/pattern handler |
| `spec/grape-swagger/openapi/conditional_schema_builder_spec.rb` | ConditionalSchemaBuilder specs |
| `spec/grape-swagger/openapi/dependent_schema_handler_spec.rb` | DependentSchemaHandler specs |
| `spec/grape-swagger/openapi/additional_properties_handler_spec.rb` | AdditionalPropertiesHandler specs |

## Test Coverage

- Conditional schemas: if/then, if/then/else, nested, allOf composition,
  edge cases, Swagger 2.0 stripping, immutability
- Dependent schemas: single/multiple dependencies, array/schema/mixed,
  nested, circular, edge cases, Swagger 2.0 passthrough, immutability
- Additional properties: boolean, schema, unevaluated (3.1.0 only),
  pattern properties (native vs extension), non-object guard,
  edge cases, immutability
