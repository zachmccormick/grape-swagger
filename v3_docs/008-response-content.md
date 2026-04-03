# PR 8: Response Content Wrapping

## User Story

As a developer using grape-swagger with OpenAPI 3.1.0, I want my response schemas to be automatically wrapped in the OpenAPI 3.1.0 content object structure, so that my API documentation conforms to the OpenAPI 3.1.0 specification where responses use `content -> mediaType -> schema` instead of the Swagger 2.0 flat `schema` format.

## Acceptance Criteria

1. ResponseContentBuilder transforms `{ schema: {...}, description: "OK" }` into `{ content: { "application/json": { schema: {...} } }, description: "OK" }` for OpenAPI 3.1.0
2. ResponseContentBuilder returns responses unchanged for Swagger 2.0
3. ResponseContentBuilder handles empty responses (no schema -> no content, just description)
4. ResponseContentBuilder handles $ref passthrough (returns $ref responses unchanged)
5. ResponseContentBuilder uses SchemaResolver to translate $ref paths from `#/definitions/` to `#/components/schemas/`
6. HeaderBuilder transforms Swagger 2.0 flat header properties (type, format, etc.) into OpenAPI 3.1.0 schema-based format
7. HeaderBuilder returns headers unchanged for Swagger 2.0
8. Response content wrapping is integrated into endpoint.rb for OpenAPI 3.1.0 output
9. All existing 807 tests continue to pass

## Components

- `lib/grape-swagger/openapi/header_builder.rb` - HeaderBuilder class
- `lib/grape-swagger/openapi/response_content_builder.rb` - ResponseContentBuilder class
- `lib/grape-swagger/endpoint.rb` - Integration of response content wrapping
- `spec/grape-swagger/openapi/header_builder_spec.rb` - HeaderBuilder unit tests
- `spec/grape-swagger/openapi/response_content_builder_spec.rb` - ResponseContentBuilder unit tests
- `spec/openapi_v3_1/response_content_integration_spec.rb` - Integration tests
