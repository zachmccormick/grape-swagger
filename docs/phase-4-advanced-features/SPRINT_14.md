# Sprint 14: Discriminator & Polymorphism
## Phase 4 - Advanced Features

### Sprint Overview
**Duration**: 2 days
**Sprint Goal**: Enhance polymorphic schema support with discriminator mapping and improved oneOf/anyOf handling.

### User Stories

#### Story 14.1: Discriminator with Mapping
**As an** API designer
**I want** discriminator with explicit mapping
**So that** polymorphic types are clearly documented

**Acceptance Criteria**:
- [ ] Discriminator propertyName defined
- [ ] Explicit mapping to schema refs
- [ ] Implicit mapping by schema name
- [ ] Discriminator in allOf compositions
- [ ] Discriminator in oneOf/anyOf

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Discriminator with propertyName only
- Discriminator with explicit mapping
- Mapping to local schema refs
- Mapping to external refs
- Discriminator in allOf
- Discriminator in oneOf
- Discriminator in anyOf
- Swagger 2.0 discriminator (simpler format)
```

#### Story 14.2: OneOf Schema Support
**As a** developer
**I want** to use oneOf for exclusive alternatives
**So that** exactly one schema matches

**Acceptance Criteria**:
- [ ] oneOf array of schemas
- [ ] oneOf with discriminator
- [ ] Inline schemas in oneOf
- [ ] Referenced schemas in oneOf
- [ ] oneOf in properties
- [ ] oneOf in response schemas

**TDD Tests Required**:
```ruby
# RED Phase tests:
- oneOf with two schemas
- oneOf with multiple schemas
- oneOf with discriminator
- Inline schemas in oneOf
- $ref schemas in oneOf
- oneOf in property definition
- oneOf in response body
- Swagger 2.0 converts to anyOf (close equivalent)
```

#### Story 14.3: AnyOf Schema Support
**As a** developer
**I want** to use anyOf for flexible matching
**So that** one or more schemas can match

**Acceptance Criteria**:
- [ ] anyOf array of schemas
- [ ] anyOf with discriminator
- [ ] anyOf vs oneOf distinction
- [ ] anyOf for partial matches
- [ ] anyOf with required properties

**TDD Tests Required**:
```ruby
# RED Phase tests:
- anyOf with two schemas
- anyOf with multiple schemas
- anyOf with discriminator
- anyOf for optional extension
- anyOf with nullable type
- Distinction from oneOf in validation
```

#### Story 14.4: Polymorphic Entity Support
**As a** Grape user
**I want** grape-entity polymorphism to generate proper schemas
**So that** entity inheritance is documented

**Acceptance Criteria**:
- [ ] Entity inheritance maps to allOf
- [ ] Entity with discriminator field
- [ ] Multiple entity types in response
- [ ] Entity exposure conditions
- [ ] Nested polymorphic entities

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Entity inheritance generates allOf
- Child entity extends parent
- Discriminator from entity attribute
- Array of polymorphic entities
- Conditional entity exposure
- Deeply nested inheritance
```

### Technical Implementation

#### Discriminator with Mapping
```yaml
components:
  schemas:
    Pet:
      type: object
      required:
        - petType
      properties:
        petType:
          type: string
        name:
          type: string
      discriminator:
        propertyName: petType
        mapping:
          dog: '#/components/schemas/Dog'
          cat: '#/components/schemas/Cat'
          bird: '#/components/schemas/Bird'

    Dog:
      allOf:
        - $ref: '#/components/schemas/Pet'
        - type: object
          properties:
            breed:
              type: string
            barkVolume:
              type: integer

    Cat:
      allOf:
        - $ref: '#/components/schemas/Pet'
        - type: object
          properties:
            whiskerLength:
              type: integer
            indoor:
              type: boolean
```

#### OneOf with Discriminator
```yaml
components:
  schemas:
    Response:
      oneOf:
        - $ref: '#/components/schemas/SuccessResponse'
        - $ref: '#/components/schemas/ErrorResponse'
      discriminator:
        propertyName: status
        mapping:
          success: '#/components/schemas/SuccessResponse'
          error: '#/components/schemas/ErrorResponse'
```

#### Ruby Implementation
```ruby
module GrapeSwagger
  module OpenAPI
    class DiscriminatorBuilder
      def self.build(discriminator_config, version)
        return nil unless discriminator_config
        return build_swagger_2_0(discriminator_config) if version.swagger_2_0?

        build_openapi_3_1(discriminator_config)
      end

      private

      def self.build_openapi_3_1(config)
        result = {
          propertyName: config[:property_name]
        }

        if config[:mapping]
          result[:mapping] = build_mapping(config[:mapping])
        end

        result
      end

      def self.build_swagger_2_0(config)
        # Swagger 2.0 only supports propertyName
        config[:property_name]
      end

      def self.build_mapping(mapping)
        mapping.transform_values do |ref|
          ref.start_with?('#') ? ref : "#/components/schemas/#{ref}"
        end
      end
    end

    class PolymorphicSchemaBuilder
      def self.build_one_of(schemas, discriminator, version)
        return nil unless version.openapi_3_1_0?

        result = {
          oneOf: schemas.map { |s| normalize_schema_ref(s) }
        }

        if discriminator
          result[:discriminator] = DiscriminatorBuilder.build(discriminator, version)
        end

        result
      end

      def self.build_any_of(schemas, discriminator, version)
        return nil unless version.openapi_3_1_0?

        result = {
          anyOf: schemas.map { |s| normalize_schema_ref(s) }
        }

        if discriminator
          result[:discriminator] = DiscriminatorBuilder.build(discriminator, version)
        end

        result
      end

      def self.build_all_of(base_schema, extension_schema, version)
        {
          allOf: [
            normalize_schema_ref(base_schema),
            extension_schema
          ]
        }
      end

      private

      def self.normalize_schema_ref(schema)
        return schema if schema.is_a?(Hash)

        { '$ref' => "#/components/schemas/#{schema}" }
      end
    end
  end
end
```

### Configuration API
```ruby
# Using grape-entity with inheritance
class Pet < Grape::Entity
  expose :pet_type, as: :petType
  expose :name
end

class Dog < Pet
  expose :breed
  expose :bark_volume, as: :barkVolume
end

class Cat < Pet
  expose :whisker_length, as: :whiskerLength
  expose :indoor
end

# In API definition
desc 'Get a pet',
  success: {
    code: 200,
    model: Pet,
    discriminator: {
      property_name: 'petType',
      mapping: {
        'dog' => Dog,
        'cat' => Cat
      }
    }
  }
get '/pets/:id' do
  # ...
end

# Or with oneOf for responses
desc 'Process request',
  success: {
    code: 200,
    one_of: [SuccessResponse, ErrorResponse],
    discriminator: {
      property_name: 'status'
    }
  }
```

### Definition of Done
- [ ] TDD: All RED tests written
- [ ] TDD: All tests GREEN
- [ ] TDD: Code refactored
- [ ] Discriminator mapping works
- [ ] oneOf schemas supported
- [ ] anyOf schemas supported
- [ ] Entity inheritance generates allOf
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 8
- **Estimated Hours**: 16
- **Risk Level**: Medium
- **Dependencies**: Sprints 11-13 complete

### Phase 4 Completion Checklist
After Sprint 14, Phase 4 should have:
- [ ] Webhooks documentation working
- [ ] Callbacks with runtime expressions
- [ ] Links for operation chaining
- [ ] OAuth2 with all flows
- [ ] OpenID Connect support
- [ ] Mutual TLS documentation
- [ ] Discriminator with mapping
- [ ] oneOf/anyOf schemas
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Ready for Phase 5

---

**Next Phase**: Phase 5 will focus on production readiness with performance optimization, documentation, and release preparation.
