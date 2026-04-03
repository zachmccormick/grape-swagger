# PR 14: Discriminator & Polymorphism

## Overview

Adds support for OpenAPI 3.1.0 discriminator objects and polymorphic schema
composition (oneOf, anyOf, allOf). Includes automatic transformation of
Swagger 2.0 string discriminators to the full Discriminator Object format.

## Components

### DiscriminatorBuilder

Builds discriminator objects appropriate for the target OpenAPI version.

- **OpenAPI 3.1.0**: Returns `{ propertyName: "...", mapping: { ... } }` with
  normalized `$ref` paths in the mapping
- **Swagger 2.0**: Returns the property name as a plain string (the only format
  Swagger 2.0 supports)
- Normalizes mapping refs: bare names become `#/components/schemas/Name`,
  existing `#/` and `http(s)://` refs are preserved

### PolymorphicSchemaBuilder

Builds polymorphic schema composition objects.

- **`build_one_of`**: Exclusive alternatives. Returns `nil` for Swagger 2.0.
- **`build_any_of`**: Flexible matching. Returns `nil` for Swagger 2.0.
- **`build_all_of`**: Entity inheritance. Works in both versions.
- All builders normalize schema references: strings become component `$ref`s,
  hashes (inline or `$ref`) pass through unchanged.

### DiscriminatorTransformer

Phase 6 transformer that converts Swagger 2.0 style string discriminators to
OpenAPI 3.1.0 Discriminator Objects during output generation.

- Builds parent-child relationships by scanning `allOf` references
- Extracts discriminator values from child schema enum properties
- Handles entity name patterns (e.g., `V1_Entities_Dog` derives `dog`)
- Converts CamelCase to snake_case for discriminator values
- Fixes child enum values to match derived discriminator values
- Skips transformation for Swagger 2.0 output (no-op)
- Skips already-transformed discriminators (Hash format)

## Pipeline Integration

The DiscriminatorTransformer runs in the `doc_methods.rb` transformation
pipeline for OpenAPI 3.x output, after `$ref` path and file type transforms
and before nullable type and binary format transforms:

1. `transform_definition_refs!` - `#/definitions/` to `#/components/schemas/`
2. `transform_file_types!` - `type: file` to `type: string, format: binary`
3. **`DiscriminatorTransformer.transform`** - string discriminators to objects
4. `transform_nullable_types!` - `nullable: true` to type arrays
5. `transform_binary_formats!` - `format: binary` to `contentEncoding`

## Files

- `lib/grape-swagger/openapi/discriminator_builder.rb`
- `lib/grape-swagger/openapi/polymorphic_schema_builder.rb`
- `lib/grape-swagger/openapi/discriminator_transformer.rb`
- `lib/grape-swagger/doc_methods.rb` (modified)
- `lib/grape-swagger.rb` (modified - requires)
- `spec/grape-swagger/openapi/discriminator_builder_spec.rb`
- `spec/grape-swagger/openapi/polymorphic_schema_builder_spec.rb`
- `spec/grape-swagger/openapi/discriminator_transformer_spec.rb`
