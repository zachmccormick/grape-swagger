# 004: Type System Modernization

## User Stories

### As a developer, I can map Grape types to version-appropriate OpenAPI/Swagger schema types using TypeMapper, with full JSON Schema 2020-12 compliance for OpenAPI 3.1.0.

**Acceptance criteria:**
- `TypeMapper.map(grape_type, version)` returns version-appropriate type mappings
- OpenAPI 3.1.0 mappings follow JSON Schema 2020-12 conventions:
  - Integer/number types have no format specifiers (int32, int64, float, double removed)
  - `long` type uses min/max constraints instead of int64 format
  - Binary data uses `contentEncoding` and `contentMediaType` instead of format
  - String formats (email, uuid, uri, hostname, ipv4, ipv6) are annotation-only
  - Date/time formats preserved as annotations
- Swagger 2.0 mappings maintain legacy `[type, format]` array structure
- Unknown types default to `{type: 'string'}` (3.1.0) or `'string'` (2.0)
- Default version is '3.1.0' when not specified
- `TypeMapper.map_with_type_array(types, version)` supports union types for OpenAPI 3.1.0
  - Single types delegate to `.map`
  - Arrays return `{type: ['string', 'number']}` union format
  - Duplicate types are deduplicated
  - Empty arrays raise `ArgumentError`
  - Swagger 2.0 falls back to first type only
- `TypeMapper.to_json_schema_type(mapping)` passes through mappings (already JSON Schema 2020-12 compliant)

### As a developer, the existing DataType.mapping method supports version-aware delegation to TypeMapper.

**Acceptance criteria:**
- `DataType.mapping(value, version)` accepts optional `version` parameter
- When version is `'3.1.0'`, delegates to `TypeMapper.map`
- When version is `nil` or any other value, uses legacy `PRIMITIVE_MAPPINGS` behavior
- Full backward compatibility maintained for existing callers

## Components

| Component | Purpose |
|-----------|---------|
| `TypeMapper` | Version-aware type mapping with two dictionaries: `OPENAPI_3_1_TYPES` (JSON Schema 2020-12) and `SWAGGER_2_0_TYPES` (legacy); provides `.map`, `.map_with_type_array`, `.to_json_schema_type`, and private `.map_swagger_2_0` |
| `DataType.mapping` (modified) | Enhanced with optional `version` parameter; delegates to `TypeMapper` for version '3.1.0'; preserves legacy behavior as default |
