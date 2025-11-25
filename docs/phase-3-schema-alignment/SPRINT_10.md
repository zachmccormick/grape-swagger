# Sprint 10: Advanced Validation Features
## Phase 3 - Schema Alignment

### Sprint Overview
**Duration**: 4 days
**Sprint Goal**: Implement JSON Schema 2020-12 advanced validation capabilities for OpenAPI 3.1.0.

### User Stories

#### Story 10.1: Conditional Schema Support
**As an** API designer
**I want** to use conditional schemas
**So that** I can express complex validation rules

**Acceptance Criteria**:
- [ ] `if/then/else` conditional schemas supported
- [ ] Conditions based on property values
- [ ] Nested conditionals allowed
- [ ] Integration with existing schema builders
- [ ] Grape DSL extension for conditionals

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Simple if/then schema
- if/then/else schema
- Nested conditional schemas
- Conditional based on enum value
- Conditional with required properties
- Multiple conditions (allOf with ifs)
- Swagger 2.0 ignores conditionals (not supported)
```

#### Story 10.2: Dependent Schemas
**As a** developer
**I want** to define dependent schemas
**So that** property presence can affect validation

**Acceptance Criteria**:
- [ ] `dependentSchemas` keyword supported
- [ ] `dependentRequired` keyword supported
- [ ] Property dependencies expressed
- [ ] Multiple dependencies allowed
- [ ] Integration with entity definitions

**TDD Tests Required**:
```ruby
# RED Phase tests:
- dependentSchemas with single dependency
- dependentSchemas with multiple dependencies
- dependentRequired for conditional required
- Nested dependent schemas
- Circular dependency detection
- Swagger 2.0 uses x-dependentSchemas extension
```

#### Story 10.3: Additional Properties Control
**As an** API consumer
**I want** control over additional properties
**So that** object schemas are properly constrained

**Acceptance Criteria**:
- [ ] `additionalProperties` boolean support
- [ ] `additionalProperties` schema support
- [ ] `unevaluatedProperties` keyword (3.1.0 only)
- [ ] Pattern properties integration
- [ ] Proper defaults for strict mode

**TDD Tests Required**:
```ruby
# RED Phase tests:
- additionalProperties: false
- additionalProperties: true
- additionalProperties with schema
- unevaluatedProperties: false
- unevaluatedProperties with schema
- Combination with patternProperties
- Swagger 2.0 additionalProperties unchanged
```

#### Story 10.4: Pattern Properties
**As a** developer
**I want** to validate property names by pattern
**So that** dynamic properties are properly typed

**Acceptance Criteria**:
- [ ] `patternProperties` keyword supported
- [ ] Regex patterns validated
- [ ] Multiple patterns allowed
- [ ] Combination with properties
- [ ] Integration with additionalProperties

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Single pattern property
- Multiple pattern properties
- Pattern with specific schema
- Pattern combined with static properties
- Overlapping patterns
- Invalid regex detection
- Swagger 2.0 uses x-patternProperties extension
```

### Technical Tasks

#### Task 10.1: ConditionalSchemaBuilder
- [ ] Create `conditional_schema_builder.rb`
- [ ] Handle if/then/else structures
- [ ] Support nested conditionals
- [ ] Validate conditional structure

**Implementation Structure**:
```ruby
module GrapeSwagger
  module OpenAPI
    class ConditionalSchemaBuilder
      def self.build(schema, version)
        return schema unless version.openapi_3_1_0?
        return schema unless has_conditionals?(schema)

        {
          if: build_condition(schema[:if]),
          then: build_schema(schema[:then]),
          else: build_schema(schema[:else])
        }.compact.merge(base_schema(schema))
      end

      private

      def self.has_conditionals?(schema)
        schema.key?(:if) || schema.key?(:then) || schema.key?(:else)
      end

      def self.build_condition(condition)
        return nil unless condition
        # Build the condition schema
        condition
      end
    end
  end
end
```

#### Task 10.2: DependentSchemaHandler
- [ ] Create `dependent_schema_handler.rb`
- [ ] Handle dependentSchemas
- [ ] Handle dependentRequired
- [ ] Support legacy dependencies conversion

**Implementation Structure**:
```ruby
module GrapeSwagger
  module OpenAPI
    class DependentSchemaHandler
      def self.transform(schema, version)
        return schema unless version.openapi_3_1_0?

        result = schema.dup

        # Convert dependencies to new format
        if result[:dependencies]
          convert_dependencies(result)
        end

        result
      end

      private

      def self.convert_dependencies(schema)
        deps = schema.delete(:dependencies)

        deps.each do |prop, value|
          if value.is_a?(Array)
            # Property list -> dependentRequired
            schema[:dependentRequired] ||= {}
            schema[:dependentRequired][prop] = value
          else
            # Schema -> dependentSchemas
            schema[:dependentSchemas] ||= {}
            schema[:dependentSchemas][prop] = value
          end
        end
      end
    end
  end
end
```

#### Task 10.3: AdditionalPropertiesHandler
- [ ] Create `additional_properties_handler.rb`
- [ ] Handle additionalProperties
- [ ] Handle unevaluatedProperties (3.1.0 only)
- [ ] Support patternProperties

**Implementation Structure**:
```ruby
module GrapeSwagger
  module OpenAPI
    class AdditionalPropertiesHandler
      def self.apply(schema, version, options = {})
        return schema unless schema[:type] == 'object'

        result = schema.dup

        if version.openapi_3_1_0? && options[:unevaluated] == false
          result[:unevaluatedProperties] = false
        end

        if options[:pattern_properties]
          result[:patternProperties] = build_pattern_properties(
            options[:pattern_properties]
          )
        end

        result
      end

      private

      def self.build_pattern_properties(patterns)
        patterns.transform_values { |v| normalize_schema(v) }
      end
    end
  end
end
```

#### Task 10.4: Integration
- [ ] Add Grape DSL extensions for new keywords
- [ ] Integrate handlers into schema generation
- [ ] Update entity parsing for new keywords
- [ ] Ensure backward compatibility

### Definition of Done
- [ ] All RED tests written first
- [ ] All tests GREEN
- [ ] Code refactored
- [ ] Conditional schemas working
- [ ] Dependent schemas working
- [ ] Additional properties control working
- [ ] Pattern properties working
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 13
- **Estimated Hours**: 32
- **Risk Level**: Medium-High
- **Dependencies**: Sprints 8-9 complete

### Schema Examples

#### Conditional Schema (if/then/else)
```yaml
# OpenAPI 3.1.0
type: object
properties:
  payment_type:
    type: string
    enum: [credit_card, bank_transfer]
if:
  properties:
    payment_type:
      const: credit_card
then:
  properties:
    card_number:
      type: string
  required:
    - card_number
else:
  properties:
    bank_account:
      type: string
  required:
    - bank_account
```

#### Dependent Schemas
```yaml
# OpenAPI 3.1.0
type: object
properties:
  name:
    type: string
  email:
    type: string
  phone:
    type: string
dependentRequired:
  email:
    - name
dependentSchemas:
  phone:
    properties:
      phone_type:
        type: string
        enum: [mobile, landline]
    required:
      - phone_type
```

#### Pattern Properties
```yaml
# OpenAPI 3.1.0
type: object
properties:
  id:
    type: string
patternProperties:
  "^x-":
    type: string
    description: Extension fields
  "^attr_":
    type: integer
additionalProperties: false
```

#### Unevaluated Properties
```yaml
# OpenAPI 3.1.0 (used with allOf composition)
allOf:
  - $ref: '#/components/schemas/BaseObject'
  - type: object
    properties:
      extended_field:
        type: string
unevaluatedProperties: false
```

### Phase 3 Completion Checklist
After Sprint 10, Phase 3 should have:
- [ ] Type system aligned with JSON Schema 2020-12
- [ ] Nullable types using type arrays
- [ ] Binary data with contentEncoding
- [ ] Conditional schemas (if/then/else)
- [ ] Dependent schemas
- [ ] Pattern properties
- [ ] UnevaluatedProperties
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Ready for Phase 4

---

**Next Phase**: Phase 4 will implement advanced OpenAPI 3.1.0 features including webhooks, callbacks, and enhanced security models.
