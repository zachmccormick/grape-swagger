# OpenAPI 3.1.0 Specification Support

This directory documents grape-swagger's support for the OpenAPI 3.1.0 specification.

Each file corresponds to an object in the [OpenAPI Specification](https://swagger.io/specification/).

## Support Status Legend

- :white_check_mark: **Supported** - Fully implemented and tested
- :construction: **Partial** - Some fields supported
- :x: **Not Supported** - Not yet implemented
- :no_entry: **N/A** - Not applicable for grape-swagger

## Object Index

### Root Level
- [OpenAPIObject](OpenAPIObject.md) - Root document object
- [InfoObject](InfoObject.md) - API metadata
- [ContactObject](ContactObject.md) - Contact information
- [LicenseObject](LicenseObject.md) - License information

### Servers
- [ServerObject](ServerObject.md) - Server connectivity
- [ServerVariableObject](ServerVariableObject.md) - Server URL variables

### Paths & Operations
- [PathsObject](PathsObject.md) - API paths container
- [PathItemObject](PathItemObject.md) - Single path operations
- [OperationObject](OperationObject.md) - Single operation definition

### Parameters & Request Bodies
- [ParameterObject](ParameterObject.md) - Operation parameters
- [RequestBodyObject](RequestBodyObject.md) - Request body definition
- [MediaTypeObject](MediaTypeObject.md) - Media type schemas
- [EncodingObject](EncodingObject.md) - Property encoding

### Responses
- [ResponsesObject](ResponsesObject.md) - Response container
- [ResponseObject](ResponseObject.md) - Single response
- [HeaderObject](HeaderObject.md) - Response headers

### Schema
- [SchemaObject](SchemaObject.md) - JSON Schema definition

### Security
- [SecuritySchemeObject](SecuritySchemeObject.md) - Security scheme definition
- [SecurityRequirementObject](SecurityRequirementObject.md) - Security requirements
- [OAuthFlowsObject](OAuthFlowsObject.md) - OAuth 2.0 flows
- [OAuthFlowObject](OAuthFlowObject.md) - Single OAuth flow

### Components
- [ComponentsObject](ComponentsObject.md) - Reusable components

### Advanced Features
- [TagObject](TagObject.md) - Tag metadata
- [ExternalDocumentationObject](ExternalDocumentationObject.md) - External docs
- [ExampleObject](ExampleObject.md) - Examples
- [LinkObject](LinkObject.md) - Operation links
- [CallbackObject](CallbackObject.md) - Callbacks
- [DiscriminatorObject](DiscriminatorObject.md) - Polymorphic discriminators
- [ReferenceObject](ReferenceObject.md) - $ref references
- [WebhookObject](WebhookObject.md) - Webhooks (3.1.0)

## Test Coverage

All supported features have corresponding tests. **524 tests pass** for OpenAPI-related functionality.

### Core Test Files

| Feature | Test File | Examples |
|---------|-----------|----------|
| Version handling | `version_spec.rb`, `version_selector_spec.rb` | Version parsing, comparison |
| Info Object | `info_builder_spec.rb` | Title, version, contact, license |
| Servers | `servers_builder_spec.rb` | URLs, variables, legacy migration |
| Security Schemes | `security_scheme_builder_spec.rb` | OAuth2, API key, Bearer, mTLS |
| Security Integration | `security_integration_spec.rb` | Operation-level security |
| Request Bodies | `request_body_builder_spec.rb` | Content types, schemas |
| Response Content | `response_content_builder_spec.rb` | Media types, examples |
| Parameters | `parameter_schema_wrapper_spec.rb` | Schema wrapping for 3.x |
| Polymorphism | `polymorphic_schema_builder_spec.rb` | oneOf, anyOf, allOf |
| Discriminators | `discriminator_builder_spec.rb` | Property name, mapping |
| Nullable Types | `nullable_type_handler_spec.rb` | Type arrays, 3.1.0 style |
| Type Mapping | `type_mapper_spec.rb` | Ruby → OpenAPI types |
| Schema Resolution | `schema_resolver_spec.rb` | Entity → schema conversion |
| Components | `components_builder_spec.rb` | Schema organization |
| References | `reference_cache_spec.rb` | $ref handling, caching |
| Integration | `integration_spec.rb`, `sprint_2_integration_spec.rb` | End-to-end tests |

### Test Locations

- `spec/openapi_v3_1/` - OpenAPI 3.1.0 specific tests
- `spec/grape-swagger/openapi/` - OpenAPI builder tests
- `spec/lib/openapi/` - OpenAPI utility tests
- `spec/lib/` - Core library tests

### Running Tests

```bash
# Run all OpenAPI tests
bundle exec rspec spec/grape-swagger/openapi/ spec/openapi_v3_1/

# Run specific feature tests
bundle exec rspec spec/grape-swagger/openapi/security_scheme_builder_spec.rb
```
