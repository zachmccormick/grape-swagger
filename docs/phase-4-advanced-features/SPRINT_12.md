# Sprint 12: Callbacks & Links
## Phase 4 - Advanced Features

### Sprint Overview
**Duration**: 3 days
**Sprint Goal**: Implement callbacks for async operations and links for operation chaining per OpenAPI 3.1.0.

### User Stories

#### Story 12.1: Callback Implementation
**As an** API provider
**I want to** document callback URLs my API will call
**So that** consumers can implement callback handlers

**Acceptance Criteria**:
- [ ] Callbacks object in operations
- [ ] Runtime expressions for callback URLs
- [ ] Callback request/response documentation
- [ ] Multiple callbacks per operation
- [ ] Callback security documentation

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Operation has callbacks object
- Callback URL with runtime expression
- Callback POST/PUT/DELETE methods
- Callback requestBody schema
- Callback response codes
- Multiple callbacks per operation
- Swagger 2.0 ignores callbacks (not supported)
```

#### Story 12.2: Runtime Expressions
**As a** developer
**I want to** use runtime expressions in callback URLs
**So that** dynamic values from requests are included

**Acceptance Criteria**:
- [ ] $url expression for original URL
- [ ] $method expression for HTTP method
- [ ] $request.body#/pointer for request values
- [ ] $request.header.X-Header for headers
- [ ] $response.body#/pointer for response values
- [ ] Expression validation

**TDD Tests Required**:
```ruby
# RED Phase tests:
- $url expression resolves
- $method expression resolves
- $request.body#/id pointer works
- $request.query.param works
- $request.header.Authorization works
- $response.body#/callbackUrl works
- Invalid expressions rejected
```

#### Story 12.3: Operation Links
**As an** API consumer
**I want to** see how operations relate to each other
**So that** I can chain API calls effectively

**Acceptance Criteria**:
- [ ] Links object in responses
- [ ] operationId or operationRef reference
- [ ] Parameter mapping expressions
- [ ] Link descriptions
- [ ] Multiple links per response

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Response has links object
- Link with operationId
- Link with operationRef
- Link parameters mapping
- Link requestBody mapping
- Link description and server
- Multiple links in response
```

#### Story 12.4: Link Runtime Expressions
**As a** developer
**I want to** map response values to linked operation parameters
**So that** API workflows are documented

**Acceptance Criteria**:
- [ ] $response.body#/pointer for mapping
- [ ] Static values in parameters
- [ ] Mixed static and dynamic values
- [ ] Header value mapping
- [ ] Request body mapping

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Parameter from response body pointer
- Static parameter value
- Mixed static and dynamic parameters
- Header value in link
- Request body reference in link
```

### Technical Implementation

#### Callback Structure Example
```yaml
paths:
  /subscribe:
    post:
      callbacks:
        onEvent:
          '{$request.body#/callbackUrl}':
            post:
              summary: Callback for subscription events
              requestBody:
                content:
                  application/json:
                    schema:
                      $ref: '#/components/schemas/Event'
              responses:
                '200':
                  description: Callback processed
        onError:
          '{$request.body#/errorUrl}':
            post:
              summary: Error notification callback
              requestBody:
                content:
                  application/json:
                    schema:
                      $ref: '#/components/schemas/Error'
```

#### Links Structure Example
```yaml
paths:
  /users:
    post:
      responses:
        '201':
          description: User created
          links:
            GetUserById:
              operationId: getUser
              parameters:
                userId: '$response.body#/id'
            GetUserPosts:
              operationRef: '#/paths/~1users~1{userId}~1posts/get'
              parameters:
                userId: '$response.body#/id'
```

#### Ruby Implementation
```ruby
module GrapeSwagger
  module OpenAPI
    class CallbackBuilder
      RUNTIME_EXPRESSION_REGEX = /\{\$[^}]+\}/.freeze

      def self.build(callbacks, version)
        return nil unless version.openapi_3_1_0?
        return nil if callbacks.nil? || callbacks.empty?

        callbacks.transform_values do |callback_config|
          build_callback(callback_config)
        end
      end

      private

      def self.build_callback(config)
        url_expression = config[:url]
        {
          url_expression => build_operation(config)
        }
      end

      def self.build_operation(config)
        {
          config[:method] || :post => {
            summary: config[:summary],
            requestBody: build_request_body(config[:request]),
            responses: config[:responses]
          }
        }
      end
    end

    class LinkBuilder
      def self.build(links, version)
        return nil unless version.openapi_3_1_0?
        return nil if links.nil? || links.empty?

        links.transform_values do |link_config|
          build_link(link_config)
        end
      end

      private

      def self.build_link(config)
        {
          operationId: config[:operation_id],
          operationRef: config[:operation_ref],
          parameters: config[:parameters],
          requestBody: config[:request_body],
          description: config[:description],
          server: config[:server]
        }.compact
      end
    end
  end
end
```

### Configuration API
```ruby
# Callbacks in route definition
desc 'Subscribe to events'
params do
  requires :callbackUrl, type: String, desc: 'URL for event callbacks'
end
post '/subscribe' do
  # ...
end

add_swagger_documentation(
  openapi_version: '3.1.0',
  callbacks: {
    '/subscribe' => {
      onEvent: {
        url: '{$request.body#/callbackUrl}',
        method: :post,
        summary: 'Event notification',
        request: {
          schema: { '$ref' => '#/components/schemas/Event' }
        },
        responses: {
          200 => { description: 'Processed' }
        }
      }
    }
  },
  links: {
    'createUser' => {
      GetUserById: {
        operation_id: 'getUser',
        parameters: { userId: '$response.body#/id' }
      }
    }
  }
)
```

### Definition of Done
- [ ] TDD: All RED tests written
- [ ] TDD: All tests GREEN
- [ ] TDD: Code refactored
- [ ] Callbacks generate correctly
- [ ] Runtime expressions work
- [ ] Links document workflows
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 13
- **Estimated Hours**: 24
- **Risk Level**: Medium-High
- **Dependencies**: Sprint 11 complete

---

**Next Sprint**: Sprint 13 will implement enhanced security models including OAuth2, OpenID Connect, and mutual TLS.
