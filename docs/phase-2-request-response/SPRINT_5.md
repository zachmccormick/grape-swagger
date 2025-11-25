# Sprint 5: Response Content Wrapping
## Phase 2 - Request/Response Transformation

### Sprint Overview
**Duration**: 2 days
**Sprint Goal**: Wrap response schemas in content type structures per OpenAPI 3.1.0 specification.

### User Stories

#### Story 5.1: Response Content Structure
**As a** spec consumer
**I want** response schemas wrapped in content objects
**So that** I can see the schema per media type

**Acceptance Criteria**:
- [ ] Response schema wrapped in content object
- [ ] Media type key (e.g., application/json)
- [ ] Schema nested under media type
- [ ] Multiple content types supported
- [ ] Headers still at response level

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Response has content object
- Content has media type key
- Schema nested under media type
- Multiple media types supported
- Headers remain at response level
- Description preserved
```

#### Story 5.2: Response Examples
**As an** API user
**I want** examples in response content
**So that** I can see sample responses

**Acceptance Criteria**:
- [ ] Example in content object
- [ ] Examples map for multiple examples
- [ ] Example per media type
- [ ] Example values preserved from Grape
- [ ] Summary and description for examples

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Single example in content
- Multiple named examples
- Media type specific examples
- Example generation from response definition
- Example descriptions included
```

#### Story 5.3: Status Code Handling
**As a** developer
**I want** proper status code responses
**So that** each status has its own content

**Acceptance Criteria**:
- [ ] Each status code has content object
- [ ] Default response supported
- [ ] Success responses (2xx)
- [ ] Error responses (4xx, 5xx)
- [ ] Empty responses handled (204)

**TDD Tests Required**:
```ruby
# RED Phase tests:
- 200 response with content
- 201 response with content
- 204 response without content
- 400 error response
- 500 error response
- Default response
```

### Technical Tasks

#### Task 5.1: ResponseContentBuilder
- [ ] Create `response_content_builder.rb`
- [ ] Build content structure
- [ ] Handle media types
- [ ] Preserve headers

**Implementation Structure**:
```ruby
class ResponseContentBuilder
  def self.build(response, produces)
    {
      description: response[:description],
      content: build_content(response[:schema], produces),
      headers: response[:headers]
    }.compact
  end

  private

  def self.build_content(schema, produces)
    return nil unless schema

    produces.each_with_object({}) do |media_type, content|
      content[media_type] = {
        schema: schema,
        examples: build_examples(schema)
      }.compact
    end
  end
end
```

#### Task 5.2: Integration with SpecBuilder
- [ ] Update response_object in endpoint.rb
- [ ] Route through ResponseContentBuilder for OpenAPI 3.1.0
- [ ] Maintain Swagger 2.0 format for backward compatibility

### Definition of Done
- [ ] All RED tests written first
- [ ] All tests GREEN
- [ ] Code refactored
- [ ] No Swagger 2.0 regression
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 8
- **Estimated Hours**: 16
- **Risk Level**: Medium
- **Dependencies**: Sprint 4 complete

---

**Next Sprint**: Sprint 6 will implement content negotiation for multiple media types.