# Sprint 16: Documentation & Migration Guide
## Phase 5 - Production Ready

### Sprint Overview
**Duration**: 4 days
**Sprint Goal**: Create comprehensive documentation for users migrating from Swagger 2.0 to OpenAPI 3.1.0 and for new adopters.

### User Stories

#### Story 16.1: Migration Guide
**As a** user with existing Swagger 2.0 APIs
**I want** a step-by-step migration guide
**So that** I can upgrade safely

**Acceptance Criteria**:
- [ ] Version comparison table
- [ ] Step-by-step migration process
- [ ] Breaking changes documented
- [ ] Configuration migration examples
- [ ] Rollback procedures
- [ ] Common issues and solutions

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Migration guide examples compile
- Before/after code samples work
- Rollback examples function
- All code snippets valid Ruby
```

#### Story 16.2: Feature Documentation
**As a** new user
**I want** to understand new OpenAPI 3.1.0 features
**So that** I can use them effectively

**Acceptance Criteria**:
- [ ] Webhooks usage guide
- [ ] Callbacks documentation
- [ ] Links documentation
- [ ] Security configuration
- [ ] Content negotiation
- [ ] JSON Schema 2020-12 features

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Webhook examples generate valid spec
- Callback examples work
- Link examples work
- Security examples work
- All examples validate against OpenAPI 3.1.0
```

#### Story 16.3: API Reference
**As a** developer
**I want** complete API reference documentation
**So that** I can use all configuration options

**Acceptance Criteria**:
- [ ] All public methods documented
- [ ] Configuration options listed
- [ ] Type signatures included
- [ ] Examples for each option
- [ ] YARD documentation complete

**TDD Tests Required**:
```ruby
# RED Phase tests:
- All public classes have YARD docs
- All public methods have YARD docs
- All examples in docs run successfully
- YARD generates without warnings
```

#### Story 16.4: Example Applications
**As a** learner
**I want** working example applications
**So that** I can see best practices

**Acceptance Criteria**:
- [ ] Simple API example
- [ ] Complex schema example
- [ ] Authentication example
- [ ] File upload example
- [ ] Polymorphic entity example
- [ ] All examples tested

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Simple API generates valid OpenAPI 3.1.0
- Complex schema example works
- Auth example includes security
- File upload generates correct encoding
- Polymorphic entities use discriminator
```

### Technical Implementation

#### Migration Guide Structure
```markdown
# Migrating from Swagger 2.0 to OpenAPI 3.1.0

## Quick Start

### Step 1: Update Configuration
```ruby
# Before (Swagger 2.0)
add_swagger_documentation(
  api_version: '1.0'
)

# After (OpenAPI 3.1.0)
add_swagger_documentation(
  openapi_version: '3.1.0',
  api_version: '1.0'
)
```

### Step 2: Update Security Definitions
...

## Breaking Changes

| Feature | Swagger 2.0 | OpenAPI 3.1.0 | Migration |
|---------|-------------|---------------|-----------|
| Nullable | `x-nullable: true` | `type: [string, null]` | Automatic |
| Binary | `type: file` | `contentEncoding: base64` | Automatic |
| ...
```

#### Feature Documentation Template
```markdown
# Webhooks

## Overview
Webhooks allow documenting async events your API publishes.

## Basic Usage

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    newOrder: {
      post: {
        summary: 'New order placed',
        request_body: {
          content: {
            'application/json' => {
              schema: { '$ref' => '#/components/schemas/Order' }
            }
          }
        }
      }
    }
  }
)
```

## Generated Output

```yaml
webhooks:
  newOrder:
    post:
      summary: New order placed
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Order'
```

## Best Practices
...
```

#### Example Application Structure
```
examples/
  simple_api/
    api.rb
    README.md
    expected_output.yaml
  complex_schemas/
    api.rb
    entities/
    README.md
  authentication/
    api.rb
    README.md
  file_uploads/
    api.rb
    README.md
  polymorphic_entities/
    api.rb
    entities/
    README.md
```

### Documentation Files

| File | Purpose | Location |
|------|---------|----------|
| MIGRATION.md | Migration guide | docs/ |
| OPENAPI_3_1_FEATURES.md | New features guide | docs/ |
| CONFIGURATION.md | All config options | docs/ |
| WEBHOOKS.md | Webhook usage | docs/ |
| CALLBACKS.md | Callback usage | docs/ |
| SECURITY.md | Security setup | docs/ |
| EXAMPLES.md | Example index | docs/ |

### Configuration Reference

```ruby
# Complete configuration reference
add_swagger_documentation(
  # Version Selection
  openapi_version: '3.1.0',  # '2.0' (default) or '3.1.0'

  # API Information
  api_version: '1.0.0',
  info: {
    title: 'My API',
    description: 'API description',
    terms_of_service: 'https://example.com/tos',
    contact: {
      name: 'API Support',
      email: 'support@example.com',
      url: 'https://example.com/support'
    },
    license: {
      name: 'MIT',
      identifier: 'MIT'  # SPDX identifier (3.1.0 only)
    }
  },

  # Servers (OpenAPI 3.1.0)
  servers: [
    {
      url: 'https://api.example.com/v1',
      description: 'Production'
    }
  ],

  # Webhooks (OpenAPI 3.1.0)
  webhooks: { ... },

  # Security
  security_definitions: { ... },
  security: [ ... ],

  # Performance
  performance: {
    cache_enabled: true,
    lazy_loading: true
  }
)
```

### Definition of Done
- [ ] TDD: All RED tests written
- [ ] TDD: All tests GREEN
- [ ] TDD: Code refactored
- [ ] Migration guide complete
- [ ] Feature docs complete
- [ ] API reference complete
- [ ] Examples working
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 8
- **Estimated Hours**: 32
- **Risk Level**: Low
- **Dependencies**: Sprint 15 complete

---

**Next Sprint**: Sprint 17 will focus on release preparation and final testing.
