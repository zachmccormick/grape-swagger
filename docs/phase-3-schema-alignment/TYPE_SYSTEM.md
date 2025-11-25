# Type System Refactoring for OpenAPI 3.1.0

## Overview

The type mapping system has been refactored to support JSON Schema 2020-12 as required by OpenAPI 3.1.0, while maintaining backward compatibility with Swagger 2.0.

## Key Components

### TypeMapper Class

The new `GrapeSwagger::OpenAPI::TypeMapper` class handles version-aware type mapping:

```ruby
# OpenAPI 3.1.0 - JSON Schema 2020-12 compliant
TypeMapper.map('integer', '3.1.0')
# => {type: 'integer'}

# Swagger 2.0 - Legacy format
TypeMapper.map('integer', '2.0')
# => ['integer', 'int32']
```

### Integration with DataType

The existing `DataType.mapping()` method now accepts an optional version parameter:

```ruby
# Defaults to Swagger 2.0 for backward compatibility
DataType.mapping('integer')
# => ['integer', 'int32']

# OpenAPI 3.1.0
DataType.mapping('integer', '3.1.0')
# => {type: 'integer'}
```

## Type Mappings

### OpenAPI 3.1.0 Mappings

Following JSON Schema 2020-12 specification:

| Grape Type | OpenAPI 3.1.0 Output | Notes |
|-----------|---------------------|-------|
| `integer` | `{type: 'integer'}` | No format specifier |
| `long` | `{type: 'integer', minimum: -2^63, maximum: 2^63-1}` | Constraints instead of format |
| `float` | `{type: 'number'}` | No format specifier |
| `double` | `{type: 'number'}` | No format specifier |
| `binary` | `{type: 'string', contentEncoding: 'base64', contentMediaType: 'application/octet-stream'}` | Uses contentEncoding |
| `byte` | `{type: 'string', contentEncoding: 'base64'}` | Uses contentEncoding |
| `date` | `{type: 'string', format: 'date'}` | Format as annotation |
| `dateTime` | `{type: 'string', format: 'date-time'}` | Format as annotation |
| `email` | `{type: 'string', format: 'email'}` | Format as annotation |
| `uuid` | `{type: 'string', format: 'uuid'}` | Format as annotation |
| `uri` | `{type: 'string', format: 'uri'}` | Format as annotation |
| `hostname` | `{type: 'string', format: 'hostname'}` | Format as annotation |
| `ipv4` | `{type: 'string', format: 'ipv4'}` | Format as annotation |
| `ipv6` | `{type: 'string', format: 'ipv6'}` | Format as annotation |
| `password` | `{type: 'string', format: 'password'}` | Format as annotation |

### Key Differences from Swagger 2.0

1. **Integer/Number Types**: No longer use `int32`, `int64`, `float`, `double` format specifiers
2. **Binary Data**: Uses `contentEncoding` and `contentMediaType` instead of format
3. **String Formats**: Treated as annotations, not validation rules
4. **Type Arrays**: Support for union types (future enhancement)

## Type Arrays (Future Enhancement)

The TypeMapper supports type arrays for union types:

```ruby
TypeMapper.map_with_type_array(['string', 'number'], '3.1.0')
# => {type: ['string', 'number']}

# Deduplicates types
TypeMapper.map_with_type_array(['string', 'string', 'number'], '3.1.0')
# => {type: ['string', 'number']}

# Handles null
TypeMapper.map_with_type_array(['string', 'null'], '3.1.0')
# => {type: ['string', 'null']}
```

## Migration Guide

### For Library Users

No changes required! The library automatically uses the appropriate type mapping based on the OpenAPI version being generated.

### For Contributors

When adding new type mappings:

1. Add to `OPENAPI_3_1_TYPES` in TypeMapper (JSON Schema 2020-12 compliant)
2. Add to `SWAGGER_2_0_TYPES` in TypeMapper (legacy format)
3. Update tests in `spec/lib/openapi/type_mapper_spec.rb`

## Testing

Comprehensive test coverage includes:

- **TypeMapper tests**: 44 examples covering all type mappings
- **DataType integration tests**: 27 examples including backward compatibility
- **Full suite**: 870 examples, all passing

## References

- [JSON Schema 2020-12](https://json-schema.org/draft/2020-12/json-schema-core.html)
- [OpenAPI 3.1.0 Specification](https://spec.openapis.org/oas/v3.1.0)
- [Sprint 8 Specification](./SPRINT_8.md)
