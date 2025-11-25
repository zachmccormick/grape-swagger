# Sprint 1: Version Management System

## Phase 1 - Foundation

### Sprint Overview

**Duration**: 3 days
**Sprint Goal**: Establish a robust version management system that allows grape-swagger to generate either Swagger 2.0
or OpenAPI 3.1.0 specifications based on user configuration.

### User Stories

#### Story 1.1: Version Configuration

**As a** grape-swagger user
**I want to** specify which OpenAPI version to generate
**So that** I can opt into OpenAPI 3.1.0 without breaking existing integrations

**Acceptance Criteria**:

- [ ] Can specify `openapi_version: '3.1.0'` in configuration
- [ ] Can specify `swagger_version: '2.0'` for explicit Swagger 2.0
- [ ] Default behavior remains Swagger 2.0 (no breaking change)
- [ ] Configuration validates version values
- [ ] Invalid versions raise clear error messages

**TDD Tests Required**:

```ruby
# RED Phase tests to write first:
-version_selector_spec.rb
-detects openapi_version parameter
-defaults to Swagger 2.0 when not specified
-validates version format
-raises error for unsupported versions
-handles swagger_version for backward compatibility
```

#### Story 1.2: Version Selector Module

**As a** grape-swagger developer
**I want to** have a central version routing system
**So that** version-specific logic is cleanly separated

**Acceptance Criteria**:

- [ ] VersionSelector module created
- [ ] Routes to appropriate spec builder based on version
- [ ] Maintains single entry point for spec generation
- [ ] Supports future version additions
- [ ] Clean separation of concerns

**TDD Tests Required**:

```ruby
# RED Phase tests to write first:
-Routing to V2_0 builder for Swagger 2.0
-Routing to V3_1 builder for OpenAPI 3.1.0
-Version object creation with proper attributes
-Options passed through correctly
-Builder interface consistency
```

#### Story 1.3: Configuration Backward Compatibility

**As an** existing grape-swagger user
**I want** my current configuration to work unchanged
**So that** I can upgrade without modifying my code

**Acceptance Criteria**:

- [ ] Existing configurations generate identical Swagger 2.0 output
- [ ] No deprecation warnings for current usage
- [ ] All existing options continue to work
- [ ] Legacy test suite passes without modification

**TDD Tests Required**:

```ruby
# RED Phase tests to write first:
-All existing Swagger 2.0 tests must pass
-Configuration compatibility tests
-Output comparison tests (before / after)
-Option forwarding tests
```

### Technical Tasks

#### Task 1.1: Create Version Infrastructure

- [ ] Create `lib/grape-swagger/openapi/` directory
- [ ] Implement `version_selector.rb`
- [ ] Create version constants file
- [ ] Add version detection to endpoint.rb

**Files to Create**:

- `lib/grape-swagger/openapi/version_selector.rb`
- `lib/grape-swagger/openapi/version_constants.rb`

**Files to Modify**:

- `lib/grape-swagger/endpoint.rb` (add version detection)
- `lib/grape-swagger.rb` (register new module)

#### Task 1.2: Implement Version Routing

- [ ] Create spec builder interface
- [ ] Implement V2_0 builder (wrapper for existing code)
- [ ] Stub V3_1 builder (to be completed in Sprint 2)
- [ ] Add version routing logic

**Code Structure**:

```ruby

module GrapeSwagger
  module OpenAPI
    class VersionSelector
      def self.build_spec(options)
        version = detect_version(options)

        case version
        when '3.1.0'
          SpecBuilder::V3_1.build(options)
        when '2.0'
          SpecBuilder::V2_0.build(options)
        else
          raise UnsupportedVersionError
        end
      end
    end
  end
end
```

#### Task 1.3: Test Implementation

- [ ] Write failing tests (RED phase)
- [ ] Implement minimum code to pass (GREEN phase)
- [ ] Refactor for clarity and performance
- [ ] Add integration tests
- [ ] Update CI configuration

### Definition of Done

- [ ] All tests passing (100% coverage for new code)
- [ ] Code reviewed by senior engineer
- [ ] No regression in Swagger 2.0 generation
- [ ] Documentation updated
- [ ] Performance benchmark shows no degradation
- [ ] Integration test suite expanded

### Sprint Metrics

- **Story Points**: 13
- **Estimated Hours**: 24
- **Risk Level**: Medium
- **Dependencies**: None

### Sprint Risks

| Risk                            | Mitigation                    |
|---------------------------------|-------------------------------|
| Breaking existing functionality | Extensive regression testing  |
| Complex version detection       | Simple explicit configuration |
| Performance impact              | Benchmark testing             |

### Next Sprint Preview

Sprint 2 will build the core OpenAPI 3.1.0 structural components using the version system established in this sprint.

---

**Note**: Implementation details will be added in `SPRINT_1_IMPLEMENTATION.md` after sprint planning approval.