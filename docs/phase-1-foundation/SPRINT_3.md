# Sprint 3: Reference Path System
## Phase 1 - Foundation

### Sprint Overview
**Duration**: 3 days
**Sprint Goal**: Implement a robust reference translation system to handle the path changes from Swagger 2.0 to OpenAPI 3.1.0.

### User Stories

#### Story 3.1: Reference Path Translation
**As a** spec generator
**I want** references to use the correct paths
**So that** schema references resolve properly in OpenAPI 3.1.0

**Acceptance Criteria**:
- [ ] `#/definitions/Model` becomes `#/components/schemas/Model`
- [ ] All $ref paths updated throughout spec
- [ ] External references supported
- [ ] Circular references handled
- [ ] Reference validation implemented

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Reference path translation for schemas
- Nested reference updates
- Array item references
- AllOf/OneOf/AnyOf references
- External file references
```

#### Story 3.2: Backward Compatible References
**As a** user with existing schemas
**I want** my references to work in both versions
**So that** migration is seamless

**Acceptance Criteria**:
- [ ] Swagger 2.0 references unchanged
- [ ] OpenAPI 3.1.0 uses new paths
- [ ] Version-aware reference generation
- [ ] No broken references during migration
- [ ] Clear error messages for invalid references

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Swagger 2.0 references remain as-is
- OpenAPI 3.1.0 references translated
- Mixed version detection
- Invalid reference handling
- Migration path validation
```

#### Story 3.3: Reference Validation
**As a** developer
**I want** references validated during generation
**So that** I catch errors early

**Acceptance Criteria**:
- [ ] Validate all internal references exist
- [ ] Check for circular dependencies
- [ ] Warn about deprecated reference styles
- [ ] Provide helpful error messages
- [ ] Option to strict validate

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Missing reference detection
- Circular reference detection
- Invalid path format detection
- Validation can be disabled
- Error messages are helpful
```

### Technical Tasks

#### Task 3.1: Schema Resolver Implementation
- [ ] Create `schema_resolver.rb`
- [ ] Implement path translation logic
- [ ] Add version awareness
- [ ] Handle nested references

**Files to Create**:
- `lib/grape-swagger/openapi/schema_resolver.rb`
- `lib/grape-swagger/openapi/reference_validator.rb`

#### Task 3.2: Update Reference Generation
- [ ] Modify model definition references
- [ ] Update parameter references
- [ ] Fix response references
- [ ] Update security references

**Files to Modify**:
- `lib/grape-swagger/doc_methods/move_params.rb`
- `lib/grape-swagger/doc_methods/build_model_definition.rb`
- `lib/grape-swagger/endpoint.rb`

#### Task 3.3: Reference Migration Utilities
- [ ] Create migration helper
- [ ] Build reference mapper
- [ ] Add deprecation warnings
- [ ] Document migration path

**Files to Create**:
- `lib/grape-swagger/openapi/reference_migrator.rb`

### Definition of Done
- [ ] All tests passing (100% coverage)
- [ ] Reference resolution working
- [ ] No broken references in output
- [ ] Performance acceptable
- [ ] Documentation complete

### Sprint Metrics
- **Story Points**: 13
- **Estimated Hours**: 24
- **Risk Level**: Medium
- **Dependencies**: Sprints 1-2

### Phase 1 Completion Checklist
- [ ] Version management operational
- [ ] OpenAPI 3.1.0 structure generating
- [ ] References properly translated
- [ ] All Swagger 2.0 tests still passing
- [ ] Documentation updated
- [ ] Ready for Phase 2

---

**Note**: With Sprint 3 complete, Phase 1 establishes the foundation for OpenAPI 3.1.0 support. Phase 2 will build upon this to handle request/response transformations.