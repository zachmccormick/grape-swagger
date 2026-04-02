# PR 6: Nullable & Binary Handling

## User Story

As a developer generating OpenAPI 3.1.0 documentation with grape-swagger,
I want `nullable: true` to be automatically transformed to JSON Schema 2020-12
type arrays (e.g., `type: ['string', 'null']`), and `format: 'binary'`/`format: 'byte'`
to be transformed to `contentEncoding`/`contentMediaType`,
so that my generated specs are fully compliant with the OpenAPI 3.1.0 standard.

## Acceptance Criteria

1. **NullableTypeHandler** transforms `nullable: true` to type arrays for OpenAPI 3.1.0
   - `{type: 'string', nullable: true}` becomes `{type: ['string', 'null']}`
   - Works for all JSON Schema types (string, integer, number, boolean, array, object)
   - Handles deduplication (no duplicate 'null' in type array)
   - Handles already-present type arrays
   - Preserves `nullable: true` unchanged for Swagger 2.0
   - Handles nil schema input gracefully

2. **BinaryDataEncoder** transforms binary/byte formats for OpenAPI 3.1.0
   - `format: 'binary'` becomes `contentEncoding: 'base64'` + `contentMediaType: 'application/octet-stream'`
   - `format: 'byte'` becomes `contentEncoding: 'base64'`
   - Supports custom `contentMediaType` override (e.g., `image/png`, `application/pdf`)
   - Non-binary formats (email, date, uuid, etc.) are left unchanged
   - Preserves `format: 'binary'` unchanged for Swagger 2.0

3. **Integration** into SchemaResolver and DocMethods
   - SchemaResolver applies nullable and binary transformations during `translate_schema`
   - DocMethods applies `transform_nullable_types!` and `transform_binary_formats!` in its pipeline
   - Deeply nested schemas are transformed correctly
   - Combined nullable + binary schemas are handled (e.g., nullable binary file upload)

## Technical Notes

- OpenAPI 3.1.0 uses JSON Schema 2020-12, which removes the `nullable` keyword
- JSON Schema 2020-12 replaces `format: 'binary'` with `contentEncoding` and `contentMediaType`
- All transformations are version-aware and backward-compatible with Swagger 2.0
- Original schemas are never mutated (immutability guarantee)
