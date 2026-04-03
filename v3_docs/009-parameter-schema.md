# PR 9: Parameter Schema Wrapping

## User Story

As a developer using grape-swagger with OpenAPI 3.1.0, I want my non-body parameter type/format/constraints to be automatically wrapped in a `schema` object with proper serialization options (style, explode), so that my API documentation conforms to the OpenAPI 3.1.0 specification where parameters use `schema: { type: ... }` instead of the Swagger 2.0 flat `type` format.

## Acceptance Criteria

1. ParameterSchemaWrapper moves schema-related fields (type, format, enum, default, minimum, maximum, minLength, maxLength, pattern, items, minItems, maxItems, uniqueItems, multipleOf, exclusiveMinimum, exclusiveMaximum, readOnly, writeOnly, minProperties, maxProperties, title, not, externalDocs) into a `schema` object for OpenAPI 3.1.0
2. ParameterSchemaWrapper returns parameters unchanged for Swagger 2.0
3. ParameterSchemaWrapper keeps non-schema fields (name, in, description, required, deprecated, allowEmptyValue, style, explode, allowReserved, example, examples, content) at the parameter level
4. ParameterSchemaWrapper adds serialization defaults per location: form for query/cookie, simple for path/header
5. ParameterSchemaWrapper handles explode defaults: true for form+array, false for simple+array
6. ParameterSchemaWrapper respects content/schema mutual exclusivity (if `content` is present, skip schema wrapping)
7. ParameterSchemaWrapper returns $ref parameters unchanged
8. ParameterSchemaWrapper converts x-example to example for OpenAPI 3.1.0
9. ParameterSchemaWrapper deep copies parameters to prevent mutation
10. Parameter schema wrapping is integrated into endpoint.rb for OpenAPI 3.1.0 output
11. All existing 871 tests continue to pass

## Components

- `lib/grape-swagger/openapi/parameter_schema_wrapper.rb` - ParameterSchemaWrapper class
- `lib/grape-swagger/endpoint.rb` - Integration of parameter schema wrapping
- `spec/grape-swagger/openapi/parameter_schema_wrapper_spec.rb` - Unit tests
- `spec/openapi_v3_1/parameter_schema_wrapping_spec.rb` - Integration tests with real Grape API
