# Sprint 2: Core Structural Components
## Phase 1 - Foundation

### Sprint Overview
**Duration**: 4 days
**Sprint Goal**: Build the core OpenAPI 3.1.0 document structure including root object, servers, and components.

### User Stories

#### Story 2.1: OpenAPI Root Object
**As a** developer using OpenAPI 3.1.0
**I want** the generated spec to have the correct root structure
**So that** it validates against OpenAPI 3.1.0 specification

**Acceptance Criteria**:
- [ ] Root contains `openapi: "3.1.0"` instead of `swagger: "2.0"`
- [ ] Info object properly structured
- [ ] Paths object maintained
- [ ] Components object created
- [ ] Valid OpenAPI 3.1.0 document structure

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Root object has openapi field
- Version is exactly "3.1.0"
- No swagger field present
- Info object validates
- Components object exists
```

#### Story 2.2: Server Configuration
**As an** API developer
**I want to** define multiple server endpoints
**So that** I can document different environments (dev, staging, prod)

**Acceptance Criteria**:
- [ ] Servers array replaces host/basePath/schemes
- [ ] Support multiple server definitions
- [ ] Server variables supported
- [ ] Backward compatible conversion from host/basePath
- [ ] Server descriptions included

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Servers array generated
- Multiple servers supported
- Variables in server URLs work
- Legacy host/basePath converts correctly
- Server descriptions included
```

#### Story 2.3: Components Structure
**As a** spec consumer
**I want** schemas organized under components
**So that** they follow OpenAPI 3.1.0 structure

**Acceptance Criteria**:
- [ ] Components object with schemas sub-object
- [ ] Definitions moved to components.schemas
- [ ] Parameters can be defined in components
- [ ] Responses can be defined in components
- [ ] Security schemes in components

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Components object structure
- Schemas properly nested
- Parameters in components
- Responses in components
- Security schemes location
```

### Technical Tasks

#### Task 2.1: OpenAPI 3.1.0 Spec Builder
- [ ] Create `spec_builder_v3_1.rb`
- [ ] Implement root object generation
- [ ] Add info object builder
- [ ] Structure components object

**Files to Create**:
- `lib/grape-swagger/openapi/spec_builder_v3_1.rb`
- `lib/grape-swagger/openapi/info_builder.rb`

#### Task 2.2: Server Array Builder
- [ ] Create `servers_builder.rb`
- [ ] Convert host/basePath/schemes to servers
- [ ] Support server variables
- [ ] Handle multiple environments

**Files to Create**:
- `lib/grape-swagger/openapi/servers_builder.rb`

#### Task 2.3: Components Builder
- [ ] Create `components_builder.rb`
- [ ] Move definitions to schemas
- [ ] Structure for parameters
- [ ] Structure for responses
- [ ] Structure for security schemes

**Files to Create**:
- `lib/grape-swagger/openapi/components_builder.rb`

### Definition of Done
- [ ] All tests passing (100% coverage)
- [ ] OpenAPI 3.1.0 structure validates
- [ ] Code review completed
- [ ] Documentation updated
- [ ] Integration tests pass

### Sprint Metrics
- **Story Points**: 21
- **Estimated Hours**: 32
- **Risk Level**: Medium-High
- **Dependencies**: Sprint 1 completion

### Next Sprint Preview
Sprint 3 will implement the reference path translation system to ensure all $ref pointers work with the new structure.