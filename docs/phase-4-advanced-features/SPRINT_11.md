# Sprint 11: Webhooks Implementation
## Phase 4 - Advanced Features

### Sprint Overview
**Duration**: 3 days
**Sprint Goal**: Implement top-level webhooks support to document asynchronous events and callbacks that the API can trigger.

### User Stories

#### Story 11.1: Webhook Definition Structure
**As an** API provider
**I want to** document webhooks my API sends
**So that** consumers know what events to expect

**Acceptance Criteria**:
- [ ] Top-level webhooks object created
- [ ] Each webhook has a unique name
- [ ] Webhook operations documented like paths
- [ ] Request body schemas defined
- [ ] Response expectations documented

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Webhooks object at root level
- Webhook names as keys
- POST/GET/PUT operations in webhooks
- RequestBody with content types
- Response codes and schemas
- No parameters array (webhooks don't have params)
```

#### Story 11.2: Webhook Configuration API
**As a** grape-swagger user
**I want to** easily define webhooks
**So that** async events are well documented

**Acceptance Criteria**:
- [ ] Simple webhook definition syntax
- [ ] Support multiple webhooks
- [ ] Webhook descriptions included
- [ ] Examples for webhook payloads
- [ ] Security requirements documented

**TDD Tests Required**:
```ruby
# RED Phase tests:
- add_webhook method exists
- Multiple webhooks can be defined
- Webhook inherits global security
- Webhook-specific security override
- Example payloads included
```

#### Story 11.3: Webhook Schema References
**As a** developer
**I want** webhooks to reference existing schemas
**So that** I don't duplicate model definitions

**Acceptance Criteria**:
- [ ] $ref to components/schemas works
- [ ] Inline schemas supported
- [ ] Shared webhook schemas
- [ ] Polymorphic webhooks with discriminator
- [ ] Array responses for batch webhooks

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Schema references resolve correctly
- Inline schema definitions work
- Shared schemas between webhooks
- Discriminator in webhook payloads
- Array schemas for batch events
```

### Technical Implementation

#### Webhook Structure Example
```yaml
webhooks:
  userSignup:
    post:
      summary: New user registration event
      requestBody:
        description: User data sent when someone signs up
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/User'
            example:
              id: 12345
              email: user@example.com
              createdAt: '2025-01-15T10:00:00Z'
      responses:
        '200':
          description: Webhook processed successfully
        '400':
          description: Invalid payload
```

#### Ruby Implementation
```ruby
module GrapeSwagger
  module OpenAPI
    class WebhookBuilder
      def self.build(webhook_definitions, options = {})
        return nil if webhook_definitions.blank?

        webhook_definitions.each_with_object({}) do |(name, config), webhooks|
          webhooks[name.to_s] = build_webhook(config, options)
        end
      end

      private

      def self.build_webhook(config, options)
        {
          post: {
            summary: config[:summary],
            description: config[:description],
            requestBody: build_request_body(config[:request]),
            responses: build_responses(config[:responses])
          }
        }
      end

      def self.build_request_body(request_config)
        return nil unless request_config

        {
          description: request_config[:description],
          required: request_config[:required] != false,
          content: build_content(request_config)
        }
      end

      def self.build_content(request_config)
        {
          'application/json' => {
            schema: build_schema(request_config[:schema]),
            examples: request_config[:examples]
          }
        }
      end
    end
  end
end
```

### Configuration API
```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  webhooks: {
    user_signup: {
      summary: 'User signup webhook',
      description: 'Triggered when a new user registers',
      request: {
        schema: { '$ref' => '#/components/schemas/User' },
        examples: {
          default: {
            value: { id: 1, email: 'user@example.com' }
          }
        }
      },
      responses: {
        200 => { description: 'Webhook received' }
      }
    }
  }
)
```

### Definition of Done
- [ ] TDD: All RED tests written
- [ ] TDD: All tests GREEN
- [ ] TDD: Code refactored
- [ ] Webhook structure validates
- [ ] Examples generate correctly
- [ ] Documentation complete

### TDD Execution Plan

#### Day 1: RED Phase
- Write failing tests for webhook structure
- Define expected webhook format
- Create validation tests

#### Day 2: GREEN Phase
- Implement WebhookBuilder
- Wire into main generation
- Make tests pass

#### Day 3: REFACTOR Phase
- Extract common patterns
- Optimize webhook generation
- Add configuration sugar

### Sprint Risks
| Risk | Mitigation |
|------|------------|
| Complex webhook expressions | Start with simple cases |
| Schema reference issues | Reuse existing resolver |
| Configuration complexity | Provide good defaults |

---

**Next Sprint**: Sprint 12 will implement callbacks and links for async operations and operation chaining.