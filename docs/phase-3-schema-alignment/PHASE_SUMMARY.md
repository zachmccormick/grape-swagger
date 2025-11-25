# Phase 3: Schema Alignment
## JSON Schema 2020-12 Compliance

### Phase Overview
**Duration**: 2 weeks (Sprints 8-10)
**Goal**: Align grape-swagger's type system with JSON Schema 2020-12 as required by OpenAPI 3.1.0, ensuring modern validation and type handling.

### Business Value
- **Standards Compliance**: Full JSON Schema 2020-12 compatibility
- **Type Safety**: Better null handling and type validation
- **Modern Features**: Support for latest schema validation features
- **Tool Compatibility**: Works with modern JSON Schema validators

### Phase Success Criteria
- [ ] Type system refactored for JSON Schema 2020-12
- [ ] Nullable types using type arrays
- [ ] Binary data with contentEncoding
- [ ] Format annotations working
- [ ] Advanced validation features available
- [ ] 100% backward compatibility maintained

### Sprint Breakdown

#### Sprint 8: Type System Refactoring (Week 5, Days 1-3)
**Focus**: Refactor core type mappings to JSON Schema 2020-12

**Key Deliverables**:
- New type mapping system
- Format handling updates
- Type array support
- Validation keyword updates

#### Sprint 9: Nullable & Binary Handling (Week 5, Days 4-5 & Week 6, Day 1)
**Focus**: Implement proper nullable types and binary data encoding

**Key Deliverables**:
- Type array nullable support
- ContentEncoding for binary
- ContentMediaType support
- File upload handling

#### Sprint 10: Advanced Validation Features (Week 6, Days 2-5)
**Focus**: Add JSON Schema 2020-12 validation capabilities

**Key Deliverables**:
- Conditional schemas (if/then/else)
- Dependent schemas
- UnevaluatedProperties
- Pattern properties

### Technical Architecture

#### Type Mapping Changes
```ruby
# Swagger 2.0
'binary' => ['string', 'binary']

# OpenAPI 3.1.0
'binary' => {
  type: 'string',
  contentEncoding: 'base64',
  contentMediaType: 'application/octet-stream'
}
```

#### Nullable Transformation
```ruby
# Swagger 2.0
{ type: 'string', nullable: true }

# OpenAPI 3.1.0
{ type: ['string', 'null'] }
```

### Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Type system breaking changes | High | Low | Version-aware mappings |
| Validator incompatibility | Medium | Medium | Test with multiple validators |
| Performance degradation | Low | Low | Benchmark testing |

### Test Strategy (TDD Approach)

#### Sprint 8 Tests
- **RED**: 30+ tests for type mappings
- **GREEN**: New mapping implementation
- **REFACTOR**: Optimize type resolution

#### Sprint 9 Tests
- **RED**: 25+ tests for nullable/binary
- **GREEN**: Type array implementation
- **REFACTOR**: Encoding optimization

#### Sprint 10 Tests
- **RED**: 20+ tests for validation features
- **GREEN**: Validation implementation
- **REFACTOR**: Performance tuning

### Definition of Done
- [ ] JSON Schema 2020-12 compliant
- [ ] All tests passing (TDD)
- [ ] Backward compatibility verified
- [ ] Performance benchmarks met
- [ ] Documentation complete

### Phase Deliverables

#### Schema Improvements
- Modern type system
- Proper null handling
- Binary data encoding
- Advanced validation

#### Developer Benefits
- Better type safety
- Clearer schemas
- Modern validation
- Tool compatibility

### Next Phase Preview
Phase 4 will implement advanced OpenAPI 3.1.0 features including webhooks, callbacks, and enhanced security models.

---

**Sprint Plans**: See individual sprint files for detailed user stories and TDD implementation plans.