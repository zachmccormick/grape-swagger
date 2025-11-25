# Sprint 6: Content Negotiation
## Phase 2 - Request/Response Transformation

### Sprint Overview
**Duration**: 3 days
**Sprint Goal**: Implement full content negotiation support with multiple media types per operation.

### User Stories

#### Story 6.1: Multiple Request Content Types
**As an** API provider
**I want** to document multiple request content types
**So that** clients know all accepted formats

**Acceptance Criteria**:
- [ ] Multiple content types in requestBody
- [ ] Different schemas per content type if needed
- [ ] Priority/preference ordering
- [ ] JSON, XML, form-data all supported
- [ ] Wildcard types supported (application/*)

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Multiple content types in requestBody
- JSON and XML together
- JSON and form-data together
- Different schemas per type
- Wildcard media types
- Content type priority
```

#### Story 6.2: Multiple Response Content Types
**As an** API consumer
**I want** to see all possible response formats
**So that** I can request my preferred format

**Acceptance Criteria**:
- [ ] Multiple content types per response
- [ ] Accept header consideration
- [ ] Schema per content type
- [ ] Examples per content type
- [ ] Default content type identified

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Multiple response content types
- JSON and XML responses
- Different examples per type
- Default content type
- Accept header mapping
```

#### Story 6.3: Content Type Encoding
**As a** developer
**I want** encoding details for multipart requests
**So that** I know how each field is encoded

**Acceptance Criteria**:
- [ ] Encoding object for multipart
- [ ] Content-Type per field
- [ ] Headers per field
- [ ] Style and explode options
- [ ] allowReserved option

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Encoding object present for multipart
- Field-level content types
- Field-level headers
- Style options
- Explode options
```

### Technical Tasks

#### Task 6.1: ContentNegotiator
- [ ] Create `content_negotiator.rb`
- [ ] Handle multiple media types
- [ ] Implement priority ordering
- [ ] Support wildcards

**Implementation Structure**:
```ruby
class ContentNegotiator
  MEDIA_TYPE_PRIORITY = {
    'application/json' => 1,
    'application/xml' => 2,
    'multipart/form-data' => 3,
    'application/x-www-form-urlencoded' => 4
  }.freeze

  def self.negotiate(consumes, produces)
    {
      request_types: prioritize(consumes),
      response_types: prioritize(produces)
    }
  end

  def self.build_content(types, schema, examples = nil)
    types.each_with_object({}) do |type, content|
      content[type] = build_media_type_object(schema, examples, type)
    end
  end
end
```

#### Task 6.2: EncodingBuilder
- [ ] Create `encoding_builder.rb`
- [ ] Handle multipart field encoding
- [ ] Support headers per field
- [ ] Style and explode options

#### Task 6.3: Integration
- [ ] Update RequestBodyBuilder to use ContentNegotiator
- [ ] Update ResponseContentBuilder to use ContentNegotiator
- [ ] Ensure consistent content structure

### Definition of Done
- [ ] All RED tests written first
- [ ] All tests GREEN
- [ ] Code refactored
- [ ] Multiple content types working
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 13
- **Estimated Hours**: 24
- **Risk Level**: Medium
- **Dependencies**: Sprints 4-5 complete

---

**Next Sprint**: Sprint 7 will migrate parameter definitions to use schema wrappers.