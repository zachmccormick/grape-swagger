# OpenAPI 3.1.0 Migration Documentation

## Overview

This documentation outlines the complete migration plan for adding OpenAPI 3.1.0 support to grape-swagger while
maintaining full backward compatibility with Swagger 2.0.

## Documentation Structure

### 📋 [Migration Roadmap](OPENAPI_3.1_MIGRATION_ROADMAP.md)

High-level overview of the entire migration project including timeline, resources, and success criteria.

### Phase Documentation

#### [Phase 1: Foundation](phase-1-foundation/)

Establishes core OpenAPI 3.1.0 infrastructure

- Sprint 1: Version Management System
- Sprint 2: Core Structural Components
- Sprint 3: Reference Path System

#### [Phase 2: Request/Response](phase-2-request-response/)

Transforms request and response handling

- Sprint 4: RequestBody Separation
- Sprint 5: Response Content Wrapping
- Sprint 6: Content Negotiation
- Sprint 7: Parameter Schema Migration

#### [Phase 3: Schema Alignment](phase-3-schema-alignment/)

Aligns with JSON Schema 2020-12

- Sprint 8: Type System Refactoring
- Sprint 9: Nullable & Binary Handling
- Sprint 10: Advanced Validation Features

#### [Phase 4: Advanced Features](phase-4-advanced-features/)

Implements modern OpenAPI 3.1.0 features

- Sprint 11: Webhooks Implementation
- Sprint 12: Callbacks & Links
- Sprint 13: Enhanced Security Models
- Sprint 14: Discriminator & Polymorphism

#### [Phase 5: Production Ready](phase-5-production-ready/)

Final optimization and release preparation

- Sprint 15: Performance Optimization
- Sprint 16: Documentation & Migration Guide
- Sprint 17: Release Preparation

## Key Principles

### Test-Driven Development (TDD)

Every sprint follows strict TDD methodology:

1. **RED**: Write failing tests first
2. **GREEN**: Implement minimum code to pass
3. **REFACTOR**: Optimize and clean up

### Backward Compatibility

- Default remains Swagger 2.0
- OpenAPI 3.1.0 is opt-in via configuration
- Zero breaking changes for existing users

### Phased Approach

- Incremental delivery over 10 weeks
- Each phase provides value independently
- Continuous integration and testing

## Quick Start for Developers

### Phase 1 Implementation

Start with [Sprint 1](phase-1-foundation/SPRINT_1.md) to establish version management.

### Testing Requirements

- Unit tests: 10-15 per feature minimum
- Integration tests: 3-5 per sprint
- Regression tests: All must pass

### Code Structure

```
lib/grape-swagger/
├── openapi/           # New OpenAPI 3.1.0 modules
│   ├── version_selector.rb
│   ├── spec_builder_v3_1.rb
│   ├── request_body_builder.rb
│   └── ...
└── doc_methods/       # Existing modules (modified)
```

## Migration for Users

### Configuration

```ruby
# Opt into OpenAPI 3.1.0
add_swagger_documentation(
  openapi_version: '3.1.0',
  servers: [
    { url: 'https://api.example.com', description: 'Production' }
  ]
)
```

### Timeline

- **v2.2.0-beta**: Early access
- **v2.2.0**: Production release
- **v2.3.0**: Deprecation warnings
- **v3.0.0**: OpenAPI 3.1.0 default

## Resources

### Technical Documentation

- [OpenAPI 3.1.0 Specification](https://swagger.io/specification/)
- [JSON Schema 2020-12](https://json-schema.org/specification-links.html#2020-12)

### Tools

- [Swagger UI](https://swagger.io/tools/swagger-ui/)
- [OpenAPI Generator](https://openapi-generator.tech/)
- [Spectral](https://stoplight.io/open-source/spectral/)

## Support

### Getting Help

- GitHub Issues: Report bugs and request features
- Discussions: Ask questions and share experiences
- Documentation: Check phase-specific guides

### Contributing

See individual sprint documentation for implementation details. All contributions must include tests following TDD
principles.

---

**Last Updated**: November 2025
**Version**: 1.0.0
**Status**: Planning Complete, Ready for Implementation