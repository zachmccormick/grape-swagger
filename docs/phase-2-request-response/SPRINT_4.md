# Sprint 4: RequestBody Separation
## Phase 2 - Request/Response Transformation

### Sprint Overview
**Duration**: 3 days
**Sprint Goal**: Separate body parameters from the parameters array and create proper RequestBody objects per OpenAPI 3.1.0 specification.

### User Stories

#### Story 4.1: Extract Body Parameters
**As an** API documentation consumer
**I want** request bodies clearly separated from other parameters
**So that** I can understand what goes in the body vs query/path

**Acceptance Criteria**:
- [ ] Body parameters removed from parameters array
- [ ] RequestBody object created for POST/PUT/PATCH
- [ ] GET/DELETE have no requestBody
- [ ] Required field properly set
- [ ] Description maintained

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Body parameters not in parameters array
- RequestBody exists for POST
- RequestBody exists for PUT
- RequestBody exists for PATCH
- No requestBody for GET
- No requestBody for DELETE
- Required field set correctly
```

#### Story 4.2: Content Type Mapping
**As a** developer
**I want** request body schemas associated with content types
**So that** I can see structure for JSON, XML, form data, etc.

**Acceptance Criteria**:
- [ ] Content object with media types
- [ ] application/json supported
- [ ] application/xml supported
- [ ] multipart/form-data supported
- [ ] application/x-www-form-urlencoded supported
- [ ] Schema per content type

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Content object structure
- JSON content type with schema
- XML content type with schema
- Form data with properties
- URL encoded forms
- Multiple content types
```

#### Story 4.3: Request Examples
**As an** API user
**I want** example request bodies
**So that** I can quickly understand the expected format

**Acceptance Criteria**:
- [ ] Examples in RequestBody
- [ ] Examples per media type
- [ ] Named examples supported
- [ ] Example values from Grape params
- [ ] Summary and description for examples

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Single example in requestBody
- Multiple named examples
- Media type specific examples
- Example generation from params
- Example descriptions
```

### Technical Tasks

#### Task 4.1: RequestBody Builder
- [ ] Create `request_body_builder.rb`
- [ ] Extract body params logic
- [ ] Build content structure
- [ ] Handle required field

**Implementation Structure**:
```ruby
class RequestBodyBuilder
  def self.build(params, method, consumes)
    return nil unless body_allowed?(method)

    body_params = extract_body_params(params)
    return nil if body_params.empty?

    {
      required: determine_required(body_params),
      content: build_content(body_params, consumes),
      description: build_description(body_params)
    }
  end

  private

  def self.body_allowed?(method)
    %w[POST PUT PATCH].include?(method)
  end

  def self.extract_body_params(params)
    params.select { |p| p[:in] == 'body' }
  end

  def self.build_content(params, consumes)
    consumes.each_with_object({}) do |media_type, content|
      content[media_type] = {
        schema: build_schema(params, media_type),
        examples: build_examples(params, media_type)
      }
    end
  end
end
```

#### Task 4.2: Modify Parameter Processing
- [ ] Update `parse_params.rb`
- [ ] Remove body parameter generation
- [ ] Route body params to RequestBodyBuilder
- [ ] Update parameter filtering

**Files to Modify**:
- `lib/grape-swagger/doc_methods/parse_params.rb`
- `lib/grape-swagger/endpoint.rb`

#### Task 4.3: Integration
- [ ] Wire RequestBodyBuilder into endpoint
- [ ] Update method_object generation
- [ ] Ensure backward compatibility
- [ ] Add version conditionals

### Definition of Done
- [ ] All RED tests written first
- [ ] All tests GREEN
- [ ] Code refactored (REFACTOR phase)
- [ ] No Swagger 2.0 regression
- [ ] Code review passed
- [ ] Documentation updated

### Sprint Metrics
- **Story Points**: 13
- **Estimated Hours**: 24
- **Risk Level**: Medium-High
- **Dependencies**: Phase 1 complete

### TDD Execution Plan

#### Day 1: RED Phase
- Write all failing tests
- Document expected behavior
- Review test coverage

#### Day 2: GREEN Phase
- Implement RequestBodyBuilder
- Make tests pass with minimal code
- Focus on correctness

#### Day 3: REFACTOR Phase
- Optimize implementation
- Extract common patterns
- Update documentation

---

**Next Sprint**: Sprint 5 will handle response content wrapping to match the request body structure.