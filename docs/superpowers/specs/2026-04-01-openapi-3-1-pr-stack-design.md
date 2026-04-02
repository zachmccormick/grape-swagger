# OpenAPI 3.1.0 PR Stack Design

## Problem

grape-swagger currently only generates Swagger 2.0 (OpenAPI 2.0) specs. We have a working implementation of OpenAPI 3.1.0 support across 6 prototype branches (`openapi3/phase-1` through `openapi3/phase-6`), but the changes are organized in large, hard-to-review chunks. Phase 6 alone is a single 19,000+ line commit that refactors much of the earlier work.

## Goal

Re-implement the OpenAPI 3.1.0 support as a clean, reviewable stack of 24 incremental PRs. Each PR is self-contained, testable, and ships with user story documentation.

## Design Principles

1. **Implement the final correct version from the start.** Phase 6 significantly refactored `endpoint.rb`, `doc_methods.rb`, `parse_params.rb`, and other files introduced in earlier phases. We use the Phase 6 architecture immediately rather than building throwaway code that gets rewritten later.

2. **Progressive demo and testing.** Each PR includes unit tests AND demo integration tests showing the feature works end-to-end. The demo app grows incrementally.

3. **Each PR ships with `v3_docs/NNN-feature.md`.** A short user story document defining what the PR implements, so reviewers understand the "why" alongside the "what."

4. **Backward compatibility throughout.** Every PR maintains 100% backward compatibility with Swagger 2.0. OpenAPI 3.1.0 features only activate when `openapi_version: '3.1.0'` is specified.

## Architecture Overview

The OpenAPI 3.1.0 implementation adds several new layers to grape-swagger:

```
Configuration Layer
  VersionSelector -> Version (with predicates: swagger_2_0?, openapi_3_1_0?)

Spec Building Layer
  SpecBuilderV3_1 orchestrates:
    InfoBuilder, ServersBuilder, ComponentsBuilder, WebhookBuilder

Schema Layer
  SchemaResolver (ref translation, transformation pipeline)
    NullableTypeHandler, BinaryDataEncoder
    ConditionalSchemaBuilder, DependentSchemaHandler, AdditionalPropertiesHandler
  TypeMapper (JSON Schema 2020-12 type mappings)
  DiscriminatorTransformer (Swagger 2.0 -> 3.1.0 discriminators)

Request/Response Layer
  RequestBodyBuilder (body params -> requestBody)
  ResponseContentBuilder + HeaderBuilder (response schema -> content wrapping)
  ParameterSchemaWrapper (param fields -> schema object)
  ContentNegotiator + EncodingBuilder (media type handling)

Advanced Features Layer
  CallbackBuilder, LinkBuilder (operation-level)
  SecuritySchemeBuilder (OAuth2, OIDC, mTLS)
  PolymorphicSchemaBuilder, DiscriminatorBuilder

Reusable Components Layer
  ComponentsRegistry
  ReusableParameter, ReusableResponse, ReusableHeader
  ReusableExample, ReusableRequestBody, ReusablePathItem

Transformation Pipeline (in DocMethods)
  transform_definition_refs! (definitions -> components/schemas)
  transform_nullable_types! (nullable:true -> type array)
  transform_binary_formats! (format:binary -> contentEncoding)
  transform_file_types! (type:file -> type:string,format:binary)
  DiscriminatorTransformer integration
  normalize_tag (snake_case -> camelCase)
```

The key architectural decision from Phase 6 is the **two-pass path processing** in `endpoint.rb`:
- **Pass 1**: Collect path-level settings (path_ref, path_servers, path-level param names) across all routes for a path
- **Pass 2**: Build operations with proper parameter filtering (path-level params separated from operation-level params)

This replaces the earlier single-pass approach and correctly handles path-level parameters, servers, and reusable path item references.

## Implementation Conventions

### Incremental `endpoint.rb` Strategy

The Phase 6 `endpoint.rb` calls into many classes introduced across multiple PRs (RequestBodyBuilder, ResponseContentBuilder, ParameterSchemaWrapper, CallbackBuilder, LinkBuilder, SecuritySchemeBuilder, ComponentsRegistry). Rather than deploying the full Phase 6 endpoint.rb in one PR, we introduce the two-pass architecture in PR 7 and each subsequent PR adds its integration points:

- **PR 7**: Two-pass architecture + RequestBody integration. Uses simplified content type logic (hardcodes `application/json`). Version-guarded stubs for features not yet implemented.
- **PR 8**: Adds ResponseContentBuilder + HeaderBuilder calls to endpoint.rb
- **PR 9**: Adds ParameterSchemaWrapper calls to endpoint.rb
- **PR 11**: Adds SecuritySchemeBuilder calls to endpoint.rb
- **PR 13**: Adds CallbackBuilder + LinkBuilder calls to endpoint.rb
- **PR 16**: Adds ComponentsRegistry integration to endpoint.rb
- **PR 20**: Adds path_params, path_ref, path_servers to endpoint.rb
- **PR 21**: Adds wildcard status codes + operation servers to endpoint.rb

### `lib/grape-swagger.rb` Requires

Each PR adds its own `require` line(s) to `lib/grape-swagger.rb`. This file is modified in nearly every PR.

### `doc_methods.rb` Progressive Enhancement

The transformation pipeline in `doc_methods.rb` is built incrementally:
- **PR 5**: `transform_definition_refs!`, `transform_file_types!`, `normalize_tag`, schema placement in `components/schemas`
- **PR 6**: Adds `transform_nullable_types!`, `transform_binary_formats!`
- **PR 14**: Adds `DiscriminatorTransformer.transform` integration

### Test Directory Convention

- `spec/grape-swagger/openapi/` - unit tests for OpenAPI builder classes
- `spec/lib/openapi/` - unit tests for schema-layer handlers
- `spec/openapi_v3_1/` - integration tests for OpenAPI 3.1.0 features
- `spec/integration/` - cross-feature integration tests

### Demo App Growth

The demo app is scaffolded in PR 1 and grows incrementally:
- **PR 1**: Scaffold with basic Grape API and `openapi_version: '3.1.0'`
- **PR 7**: POST/PUT endpoints in users_api.rb/orders_api.rb showing requestBody
- **PR 8**: Response entity examples in pets_api.rb
- **PR 11**: admin_api.rb with OAuth2/OIDC/mTLS security
- **PR 12**: Webhook definitions in root.rb
- **PR 13**: callbacks_links_demo_api.rb
- **PR 14**: Pet hierarchy (Dog/Cat/Bird) with discriminator in pets_api.rb
- **PR 16**: Reusable headers/params in initializers
- **PR 24**: TypeScript SDK demo (demo-ts/, ~5,800 lines auto-generated)

### Existing `openapi/errors.rb` Namespace

The codebase already has `lib/grape-swagger/errors.rb` (`GrapeSwagger::Errors`). PR 1 introduces `lib/grape-swagger/openapi/errors.rb` (`GrapeSwagger::OpenAPI::Errors`). These coexist without conflict.

## PR Stack (24 PRs)

### Foundation (PRs 1-4)

**PR 1: Version Management System**
- Version detection, validation, and predicates
- Demo app scaffold with `openapi_version: '3.1.0'`
- New files: `openapi/version_constants.rb`, `openapi/errors.rb`, `openapi/version.rb`, `openapi/version_selector.rb`
- Modified: `grape-swagger.rb` (+3 requires)
- Tests: version_spec, version_selector_spec, integration_spec
- Demo: scaffold + basic configuration

**PR 2: Core Spec Builders**
- InfoBuilder, ServersBuilder, ComponentsBuilder, SpecBuilderV3_1
- Correct top-level OpenAPI 3.1.0 structure
- New files: `openapi/info_builder.rb`, `openapi/servers_builder.rb`, `openapi/components_builder.rb`, `openapi/spec_builder_v3_1.rb`
- Modified: `grape-swagger.rb` (+4 requires)
- Tests: info_builder_spec, servers_builder_spec, components_builder_spec, spec_builder_v3_1_spec, integration spec

**PR 3: Schema Resolution & Reference Validation**
- SchemaResolver ($ref path translation), ReferenceValidator
- ComponentsBuilder integration for ref translation
- New files: `openapi/schema_resolver.rb`, `openapi/reference_validator.rb`
- Modified: `grape-swagger.rb` (+2 requires), `openapi/components_builder.rb`
- Tests: schema_resolver_spec, reference_validator_spec

**PR 4: Type System Modernization**
- TypeMapper with JSON Schema 2020-12 compliant types
- DataType delegation for version-aware mapping
- New files: `openapi/type_mapper.rb`
- Modified: `grape-swagger.rb` (+1 require), `doc_methods/data_type.rb`
- Tests: type_mapper_spec, data_type_spec additions
- Demo: endpoint with various types showing correct mappings

### Schema Transforms (PRs 5-6)

**PR 5: Schema Transformation Pipeline**
- DocMethods transformation pipeline (Phase 6 architecture)
- `transform_definition_refs!`, `transform_file_types!`, `normalize_tag`
- Schemas placed in `components/schemas` instead of `definitions`
- Modified: `doc_methods.rb`
- Tests: transformation pipeline unit tests
- Demo: verify schema placement and ref paths

**PR 6: Nullable & Binary Handling**
- NullableTypeHandler, BinaryDataEncoder
- SchemaResolver `apply_transformations` integration
- DocMethods: adds `transform_nullable_types!`, `transform_binary_formats!`
- New files: `openapi/nullable_type_handler.rb`, `openapi/binary_data_encoder.rb`
- Modified: `grape-swagger.rb` (+2 requires), `openapi/schema_resolver.rb`, `doc_methods.rb`
- Tests: nullable_type_handler_spec, binary_data_encoder_spec, integration spec
- Demo: endpoints with nullable fields and file upload parameters

### Request/Response (PRs 7-10)

**PR 7: RequestBody Separation**
- RequestBodyBuilder (Phase 6 version with all schema fields)
- Endpoint two-pass architecture (Phase 6) with version-guarded stubs for features not yet implemented
- Uses simplified content type logic (hardcodes `application/json`); PR 10 adds ContentNegotiator
- New files: `openapi/request_body_builder.rb`
- Modified: `grape-swagger.rb` (+1 require), `endpoint.rb` (two-pass architecture), `doc_methods/format_data.rb` ($ref filtering), `doc_methods/move_params.rb` (extended property_keys)
- Tests: request_body_builder_spec, integration spec
- Demo: POST/PUT endpoints showing requestBody generation

**PR 8: Response Content Wrapping**
- ResponseContentBuilder with $ref passthrough (Phase 6)
- HeaderBuilder (Phase 6 - new file)
- New files: `openapi/response_content_builder.rb`, `openapi/header_builder.rb`
- Modified: `grape-swagger.rb` (+2 requires), `endpoint.rb` (response transformation integration)
- Tests: response_content_builder_spec, header_builder_spec, integration spec
- Demo: endpoints with various response types and headers

**PR 9: Parameter Schema Wrapping**
- ParameterSchemaWrapper (Phase 6 version)
- Content/schema mutual exclusivity, extended fields, x-example conversion
- New files: `openapi/parameter_schema_wrapper.rb`
- Modified: `grape-swagger.rb` (+1 require), `endpoint.rb` (parameter wrapping)
- Tests: parameter_schema_wrapper_spec, integration spec
- Demo: endpoints with query/path/header parameters

**PR 10: Content Negotiation & Encoding**
- ContentNegotiator, EncodingBuilder
- Refactor RequestBodyBuilder and ResponseContentBuilder to use ContentNegotiator
- New files: `openapi/content_negotiator.rb`, `openapi/encoding_builder.rb`
- Modified: `grape-swagger.rb` (+2 requires), `openapi/request_body_builder.rb`, `openapi/response_content_builder.rb`
- Tests: content_negotiator_spec, encoding_builder_spec
- Demo: multipart upload endpoint with encoding config

### Advanced Features (PRs 11-15)

**PR 11: Security Scheme Builder**
- OAuth2 (all 4 flows), OpenID Connect, mutual TLS, HTTP bearer, API key
- Backward compatibility to Swagger 2.0
- New files: `openapi/security_scheme_builder.rb`
- Modified: `grape-swagger.rb` (+1 require), `endpoint.rb` (security calls), `openapi/components_builder.rb`
- Tests: security_scheme_builder_spec, security_integration_spec
- Demo: admin_api.rb with OAuth2 + OIDC + mTLS

**PR 12: Webhooks**
- Top-level webhooks object
- New files: `openapi/webhook_builder.rb`
- Modified: `grape-swagger.rb` (+1 require), `openapi/spec_builder_v3_1.rb`
- Tests: webhook_builder_spec, spec_builder_v3_1_spec additions
- Demo: webhook definitions in root.rb

**PR 13: Callbacks & Links**
- Operation-level callbacks with runtime expressions, response-level links
- New files: `openapi/callback_builder.rb`, `openapi/link_builder.rb`
- Modified: `grape-swagger.rb` (+2 requires), `endpoint.rb` (callback/link integration)
- Tests: callback_builder_spec, link_builder_spec, integration specs
- Demo: callbacks_links_demo_api.rb

**PR 14: Discriminator & Polymorphism**
- DiscriminatorBuilder, DiscriminatorTransformer (Phase 6), PolymorphicSchemaBuilder
- New files: `openapi/discriminator_builder.rb`, `openapi/discriminator_transformer.rb`, `openapi/polymorphic_schema_builder.rb`
- Modified: `grape-swagger.rb` (+3 requires), `doc_methods.rb` (DiscriminatorTransformer integration)
- Tests: discriminator_builder_spec, discriminator_transformer_spec, polymorphic_schema_builder_spec
- Demo: Pet hierarchy with discriminator

**PR 15: Advanced Schema Validation**
- if/then/else, dependentSchemas/dependentRequired, additionalProperties, unevaluatedProperties, patternProperties
- New files: `openapi/conditional_schema_builder.rb`, `openapi/dependent_schema_handler.rb`, `openapi/additional_properties_handler.rb`
- Modified: `grape-swagger.rb` (+3 requires), `openapi/schema_resolver.rb`
- Tests: conditional_schema_builder_spec, dependent_schema_handler_spec, additional_properties_handler_spec

### Reusable Components (PRs 16-17)

**PR 16: Reusable Components**
- ComponentsRegistry, ReusableParameter/Response/Header, ref DSL, pipeline integration
- New files: `components_registry.rb`, `reusable_parameter.rb`, `reusable_response.rb`, `reusable_header.rb`, `endpoint/params_extensions.rb`
- Modified: `grape-swagger.rb` (+5 requires), `endpoint.rb` (ref + response reference integration), `openapi/components_builder.rb`
- Tests: components_registry_spec, reusable_*_spec, params_extensions_spec, integration spec
- Demo: reusable headers/params in initializers

**PR 17: Extended Reusable Components**
- ReusableExample, ReusableRequestBody, ReusablePathItem
- New files: `reusable_example.rb`, `reusable_request_body.rb`, `reusable_path_item.rb`
- Modified: `grape-swagger.rb` (+3 requires), `components_registry.rb` (path item + example + requestBody support), `openapi/components_builder.rb` (pathItems), `doc_methods/tag_name_description.rb` (path item $ref guard)
- Tests: reusable_example_spec, reusable_request_body_spec, reusable_path_item_spec

### Polish (PRs 18-24)

**PR 18: Schema Validation Keys**
- uniqueItems, exclusiveMin/Max, multipleOf, range detection
- Modified: `doc_methods/parse_params.rb`, `doc_methods/move_params.rb`, `openapi/request_body_builder.rb`
- Tests: schema_validation_spec
- Demo: endpoint with validated numeric parameters

**PR 19: Advanced Parameter Features**
- content field, readOnly/writeOnly, externalDocs, minProperties/maxProperties, title, not, reference overrides (ref_summary, ref_description)
- Modified: `doc_methods/parse_params.rb` (Phase 6 extended fields), `openapi/parameter_schema_wrapper.rb`, `openapi/request_body_builder.rb`
- Tests: parameter_content_spec, object_constraints_spec, schema_title_not_spec, schema_external_docs_spec, reference_overrides_spec
- Demo: endpoints demonstrating each feature

**PR 20: Path-Level Features**
- path_params DSL (Phase 6 route_setting version), path-level servers, path references
- New files: `endpoint/path_params_extension.rb`
- Modified: `grape-swagger.rb` (+1 require), `endpoint.rb` (path_ref, path_servers, path param collection)
- Tests: path_params_extension_spec, path_operation_servers_spec

**PR 21: Wildcard Status Codes & Operation Servers**
- 1XX/2XX/3XX/4XX/5XX status codes, operation-level server overrides
- Modified: `endpoint.rb` (`wildcard_status_code?`, `servers_object`)
- Tests: wildcard_status_codes_spec, operation_properties_spec
- Demo: endpoint with wildcard error responses and custom server

**PR 22: Performance Utilities**
- ReferenceCache (thread-safe LRU), LazyComponentBuilder, BenchmarkSuite
- New files: `openapi/reference_cache.rb`, `openapi/lazy_component_builder.rb`, `openapi/benchmark_suite.rb`
- Modified: `grape-swagger.rb` (+3 requires)
- Tests: reference_cache_spec, lazy_component_builder_spec, benchmark_suite_spec

**PR 23: Regression & Security Test Suite**
- Backward compatibility regression tests, input sanitization, thread safety
- New files: regression_suite_spec, security_tests_spec
- Tests: 27 regression + 18 security tests

**PR 24: TypeScript SDK Demo & Final Polish**
- TypeScript frontend consuming generated spec via auto-generated SDK
- New files: `demo/demo-ts/` (~5,800 lines auto-generated + ~700 lines config/tests)
- Final demo app polish, documentation cleanup

## Dependency Graph

```
PR 1 (version)
├── PR 2 (builders)
│   ├── PR 3 (resolver)
│   │   ├── PR 5 (transforms)
│   │   │   ├── PR 6 (nullable/binary) [also depends on PR 4]
│   │   │   └── PR 14 (discriminator)
│   │   ├── PR 7 (requestBody + endpoint arch)
│   │   │   ├── PR 8 (response) ──> PR 10 (negotiation)
│   │   │   ├── PR 9 (param schema) ──> PR 19 (advanced params)
│   │   │   ├── PR 13 (callbacks/links)
│   │   │   ├── PR 18 (validation keys) ──> PR 19
│   │   │   ├── PR 20 (path features) [also depends on PR 17]
│   │   │   └── PR 21 (wildcards/servers)
│   │   ├── PR 15 (advanced validation)
│   │   └── PR 22 (performance)
│   ├── PR 11 (security)
│   ├── PR 12 (webhooks)
│   └── PR 16 (components) [also depends on PR 7]
│       └── PR 17 (extended components)
└── PR 4 (types) ──> PR 6 (nullable/binary)

All ──> PR 23 (regression) ──> PR 24 (demo)
```

## Parallelization Opportunities

- After PR 1: PR 4 can start
- After PR 2: PRs 11, 12 can start
- After PR 3: PRs 5, 7, 15, 22 can start
- After PR 7: PRs 8, 9, 13, 16, 18, 20, 21 can start
- After PRs 4+5: PR 6 can start
- After PR 5: PR 14 can start

## Files Modified Per PR (Phase 6 Refactoring Pull-Forward)

The following files are implemented in their Phase 6 (final) form when first introduced, then progressively enhanced:

| File | Introduced | Also Modified In | Phase 6 Changes Baked In |
|------|-----------|-------------------|------------------------|
| `grape-swagger.rb` | master | PRs 1-17, 20, 22 | Each PR adds its requires |
| `endpoint.rb` | PR 7 | PRs 8, 9, 11, 13, 16, 20, 21 | Two-pass architecture from PR 7; each PR adds its integration |
| `doc_methods.rb` | PR 5 | PRs 6, 14 | PR 5: refs/files/tags; PR 6: nullable/binary; PR 14: discriminator |
| `doc_methods/parse_params.rb` | PR 7 | PRs 18, 19 | PR 7: $ref handling; PR 18: validation keys; PR 19: extended fields |
| `doc_methods/move_params.rb` | PR 7 | PR 18 | PR 7: base property_keys; PR 18: validation keys |
| `doc_methods/format_data.rb` | PR 7 | - | $ref filtering, nil-safe access |
| `request_body_builder.rb` | PR 7 | PRs 10, 18, 19 | PR 7: schema fields; PR 10: ContentNegotiator; PRs 18-19: extended |
| `response_content_builder.rb` | PR 8 | PR 10 | PR 8: HeaderBuilder + $ref passthrough; PR 10: ContentNegotiator |
| `parameter_schema_wrapper.rb` | PR 9 | PR 19 | PR 9: content/schema exclusivity; PR 19: extended fields |
| `openapi/components_builder.rb` | PR 2 | PRs 3, 11, 16, 17 | Progressive integration with each feature |
| `openapi/schema_resolver.rb` | PR 3 | PRs 6, 15 | PR 6: apply_transformations; PR 15: advanced handlers |
| `tag_name_description.rb` | master | PR 17 | Path item $ref guard |
| `components_registry.rb` | PR 16 | PR 17 | PR 17: path item + example + requestBody support |
| `path_params_extension.rb` | PR 20 | - | route_setting architecture |

## Testing Strategy

Each PR includes:
1. **Unit tests** for each new class/module
2. **Integration tests** verifying the feature works in the spec generation pipeline
3. **Demo endpoints** in the progressive demo app showing real-world usage
4. **Backward compatibility tests** confirming Swagger 2.0 output is unchanged

## Success Criteria

- All existing Swagger 2.0 tests continue to pass at every PR
- Each PR generates valid OpenAPI 3.1.0 output for its feature area
- The final stack (all 24 PRs) produces spec-compliant OpenAPI 3.1.0 documentation
- Each PR is reviewable in a single sitting (target: <1,500 lines per PR)
