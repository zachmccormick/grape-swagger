# Sprint 7: Parameter Schema Migration
## Phase 2 - Request/Response Transformation

### Sprint Overview
**Duration**: 2 days
**Sprint Goal**: Wrap parameter definitions in schema objects per OpenAPI 3.1.0 specification.

### User Stories

#### Story 7.1: Parameter Schema Wrapping
**As a** spec consumer
**I want** parameter types wrapped in schema objects
**So that** they follow OpenAPI 3.1.0 structure

**Acceptance Criteria**:
- [ ] Type moved into schema object
- [ ] Format moved into schema object
- [ ] Enum moved into schema object
- [ ] Default moved into schema object
- [ ] Validation constraints in schema

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Query parameter has schema wrapper
- Path parameter has schema wrapper
- Header parameter has schema wrapper
- Type inside schema
- Format inside schema
- Enum inside schema
- Default inside schema
- Min/max in schema
```

#### Story 7.2: Cookie Parameters
**As an** API provider
**I want** to document cookie parameters
**So that** clients know about cookie-based auth

**Acceptance Criteria**:
- [ ] Cookie parameter location supported
- [ ] in: cookie value
- [ ] Schema for cookie value
- [ ] Multiple cookies supported
- [ ] Cookie description and required

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Cookie parameter in: cookie
- Cookie with schema
- Multiple cookie parameters
- Required cookie
- Optional cookie with default
```

#### Story 7.3: Parameter Serialization
**As a** developer
**I want** parameter serialization options
**So that** complex parameters are properly documented

**Acceptance Criteria**:
- [ ] Style option for serialization
- [ ] Explode option for arrays/objects
- [ ] allowReserved for special characters
- [ ] allowEmptyValue option
- [ ] deepObject style for nested objects

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Style: form (default for query)
- Style: simple (default for path)
- Style: spaceDelimited
- Style: pipeDelimited
- Style: deepObject
- Explode: true/false
- allowReserved option
```

### Technical Tasks

#### Task 7.1: ParameterSchemaWrapper
- [ ] Create `parameter_schema_wrapper.rb`
- [ ] Move type/format/enum into schema
- [ ] Handle validation constraints
- [ ] Preserve non-schema fields

**Implementation Structure**:
```ruby
class ParameterSchemaWrapper
  SCHEMA_FIELDS = %i[type format enum default minimum maximum
                     minLength maxLength pattern items].freeze

  def self.wrap(parameter, version)
    return parameter if version.swagger_2_0?

    wrapped = parameter.dup
    schema = extract_schema_fields(wrapped)

    wrapped[:schema] = schema unless schema.empty?
    wrapped
  end

  private

  def self.extract_schema_fields(param)
    SCHEMA_FIELDS.each_with_object({}) do |field, schema|
      schema[field] = param.delete(field) if param.key?(field)
    end
  end
end
```

#### Task 7.2: Cookie Parameter Support
- [ ] Add cookie to valid parameter locations
- [ ] Update parameter parsing for cookies
- [ ] Integrate with existing parameter handling

#### Task 7.3: Serialization Options
- [ ] Add style field support
- [ ] Add explode field support
- [ ] Add allowReserved support
- [ ] Default styles per location

### Definition of Done
- [ ] All RED tests written first
- [ ] All tests GREEN
- [ ] Code refactored
- [ ] Parameters properly wrapped
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 8
- **Estimated Hours**: 16
- **Risk Level**: Low-Medium
- **Dependencies**: Sprints 4-6 complete

### Phase 2 Completion Checklist
After Sprint 7, Phase 2 should have:
- [ ] RequestBody separated from parameters
- [ ] Response content wrapped properly
- [ ] Content negotiation working
- [ ] Parameters with schema wrappers
- [ ] Cookie parameters supported
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Ready for Phase 3

---

**Next Phase**: Phase 3 will align schemas with JSON Schema 2020-12.