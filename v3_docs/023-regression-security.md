# PR 23: Regression & Security Test Suite

## Overview

Comprehensive regression tests for backward compatibility and security tests for input sanitization across all OpenAPI 3.x builders and utilities.

## Components

### Regression Suite (`regression_suite_spec.rb`)

Cross-cutting tests that verify backward compatibility and consistent behavior across OpenAPI versions.

**Coverage areas:**
- Version selector backward compatibility (defaults to 2.0, priority, validation)
- Type mapping consistency (both versions produce valid output)
- Nullable handling (3.1.0 type arrays vs 2.0 nullable flag)
- Binary encoding (3.1.0 contentEncoding vs 2.0 format)
- Security scheme backward compatibility (apiKey, OAuth2, OpenID Connect)
- Polymorphic schema versions (oneOf/anyOf/allOf)
- Discriminator format versions (string vs object)
- Nil input handling across all handlers

### Security Tests (`security_tests_spec.rb`)

Tests for input sanitization, reference handling safety, cache isolation, type coercion, and resource limits.

**Coverage areas:**
- Input sanitization (special characters, unicode, long strings)
- Reference handling (malformed refs, path traversal attempts, external refs)
- Cache isolation (thread safety, invalidation, size limits)
- Type coercion safety (symbol vs string keys, mixed types)
- Resource limits (zero iterations, large registration counts)
- Error handling (exceptions in blocks, GC state restoration)
- Thread safety (concurrent cache access)

## Testing

```bash
# Run regression suite
bundle exec rspec spec/grape-swagger/openapi/regression_suite_spec.rb

# Run security tests
bundle exec rspec spec/grape-swagger/openapi/security_tests_spec.rb

# Run both
bundle exec rspec spec/grape-swagger/openapi/regression_suite_spec.rb spec/grape-swagger/openapi/security_tests_spec.rb
```

## Dependencies

These tests exercise the following components from prior PRs:
- Version, VersionSelector, VersionConstants (PR 1)
- TypeMapper (PR 4)
- NullableTypeHandler, BinaryDataEncoder (PR 6)
- SecuritySchemeBuilder (PR 11)
- DiscriminatorBuilder, PolymorphicSchemaBuilder (PR 14)
- WebhookBuilder (PR 12)
- ReferenceCache, LazyComponentBuilder, BenchmarkSuite (PR 22)
