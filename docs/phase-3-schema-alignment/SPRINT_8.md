# Sprint 8: Type System Refactoring
## Phase 3 - Schema Alignment

### Sprint Overview
**Duration**: 3 days
**Sprint Goal**: Refactor the core type mapping system to align with JSON Schema 2020-12 as required by OpenAPI 3.1.0.

### User Stories

#### Story 8.1: JSON Schema Type Mappings
**As a** developer using modern tooling
**I want** schemas that comply with JSON Schema 2020-12
**So that** I can use standard JSON Schema validators

**Acceptance Criteria**:
- [ ] Type mappings follow JSON Schema 2020-12
- [ ] Formats used as annotations, not validation
- [ ] Integer types without format specifiers
- [ ] String formats properly annotated
- [ ] Custom formats documented

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Integer maps to {type: 'integer'} without format
- Number maps to {type: 'number'} without format
- Binary uses contentEncoding instead of format
- Date/DateTime formats remain as annotations
- Custom formats preserved but marked as annotations
```

#### Story 8.2: Type Array Support
**As an** API designer
**I want** to use type arrays in schemas
**So that** I can express union types properly

**Acceptance Criteria**:
- [ ] Type arrays recognized and validated
- [ ] Single types work as before
- [ ] Array types properly serialized
- [ ] Validation handles type arrays
- [ ] Examples show type array usage

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Type can be string: {type: 'string'}
- Type can be array: {type: ['string', 'number']}
- Empty type array rejected
- Duplicate types in array removed
- Type array with null handled
```

### Technical Implementation

#### Core Type Mapping Refactor
```ruby
module GrapeSwagger
  module OpenAPI
    class TypeMapper
      OPENAPI_3_1_TYPES = {
        'integer' => { type: 'integer' },
        'long' => { type: 'integer', minimum: -2**63, maximum: 2**63-1 },
        'float' => { type: 'number' },
        'double' => { type: 'number' },
        'string' => { type: 'string' },
        'byte' => {
          type: 'string',
          contentEncoding: 'base64'
        },
        'binary' => {
          type: 'string',
          contentEncoding: 'base64',
          contentMediaType: 'application/octet-stream'
        },
        'boolean' => { type: 'boolean' },
        'date' => { type: 'string', format: 'date' },
        'dateTime' => { type: 'string', format: 'date-time' },
        'password' => { type: 'string', format: 'password' },
        'email' => { type: 'string', format: 'email' },
        'uuid' => { type: 'string', format: 'uuid' },
        'uri' => { type: 'string', format: 'uri' },
        'hostname' => { type: 'string', format: 'hostname' },
        'ipv4' => { type: 'string', format: 'ipv4' },
        'ipv6' => { type: 'string', format: 'ipv6' }
      }.freeze

      def self.map(grape_type, version = '3.1.0')
        return map_swagger_2_0(grape_type) if version == '2.0'

        OPENAPI_3_1_TYPES[grape_type] || { type: 'string' }
      end
    end
  end
end
```

### Definition of Done
- [ ] All RED tests written first
- [ ] GREEN phase: tests passing
- [ ] REFACTOR: code optimized
- [ ] JSON Schema 2020-12 compliant
- [ ] Performance benchmarks met
- [ ] Documentation updated

### TDD Execution Plan

#### Day 1: RED Phase
- Write comprehensive type mapping tests
- Document expected JSON Schema output
- Create validation test suite

#### Day 2: GREEN Phase
- Implement TypeMapper class
- Update data_type.rb integration
- Make all tests pass

#### Day 3: REFACTOR Phase
- Optimize type resolution
- Extract common patterns
- Performance profiling

---

**Next Sprint**: Sprint 9 will handle nullable types and binary data encoding.