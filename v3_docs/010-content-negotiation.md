# PR 10: Content Negotiation & Encoding

## User Story

As a developer using grape-swagger with OpenAPI 3.1.0, I want content negotiation support that prioritizes media types and encoding configuration for multipart fields, so that my API documentation correctly represents multiple request/response content types with proper field-level encoding metadata.

## Acceptance Criteria

1. ContentNegotiator prioritizes media types: JSON (1) > XML (2) > multipart (3) > URL-encoded (4)
2. ContentNegotiator `.negotiate(consumes, produces)` returns `{ request_types:, response_types: }`
3. ContentNegotiator `.build_content(types, schema, examples, version)` creates content objects for multiple media types
4. ContentNegotiator `.add_encoding(content, encoding_config, version)` adds encoding to multipart content only
5. ContentNegotiator handles nil/empty inputs, unknown media types, and per-type schemas
6. EncodingBuilder `.build(field_name, encoding_config, version)` builds encoding for a single field (contentType, headers, style, explode, allowReserved)
7. EncodingBuilder `.build_for_fields(encoding_config, version)` processes multiple fields
8. EncodingBuilder returns nil for nil/empty configs and skips fields with nil/empty configs
9. RequestBodyBuilder optionally uses ContentNegotiator when consumes has multiple types
10. ResponseContentBuilder optionally uses ContentNegotiator for response media types
11. All existing 947 tests continue to pass after refactoring

## Components

- `lib/grape-swagger/openapi/encoding_builder.rb` - EncodingBuilder class
- `lib/grape-swagger/openapi/content_negotiator.rb` - ContentNegotiator class
- `spec/grape-swagger/openapi/encoding_builder_spec.rb` - EncodingBuilder unit tests
- `spec/grape-swagger/openapi/content_negotiator_spec.rb` - ContentNegotiator unit tests
- `lib/grape-swagger/openapi/request_body_builder.rb` - Refactored to use ContentNegotiator
- `lib/grape-swagger/openapi/response_content_builder.rb` - Refactored to use ContentNegotiator
