# Sprint 13: Enhanced Security Models
## Phase 4 - Advanced Features

### Sprint Overview
**Duration**: 2 days
**Sprint Goal**: Implement modern security schemes including OAuth2 flows, OpenID Connect, and mutual TLS authentication.

### User Stories

#### Story 13.1: OAuth2 Flows
**As an** API provider
**I want to** document all OAuth2 flows
**So that** consumers know how to authenticate

**Acceptance Criteria**:
- [ ] Authorization Code flow supported
- [ ] Client Credentials flow supported
- [ ] Implicit flow supported (deprecated but documented)
- [ ] Password flow supported (deprecated but documented)
- [ ] Refresh token URL documented
- [ ] Scopes with descriptions

**TDD Tests Required**:
```ruby
# RED Phase tests:
- OAuth2 authorizationCode flow
- OAuth2 clientCredentials flow
- OAuth2 implicit flow (deprecated)
- OAuth2 password flow (deprecated)
- Refresh URL in OAuth2
- Scopes object with descriptions
- Multiple scopes per operation
- Swagger 2.0 OAuth2 compatibility
```

#### Story 13.2: OpenID Connect
**As an** API provider
**I want to** document OpenID Connect authentication
**So that** consumers can use OIDC for auth

**Acceptance Criteria**:
- [ ] openIdConnect security type
- [ ] openIdConnectUrl for discovery
- [ ] OIDC scopes documented
- [ ] Integration with OAuth2 flows
- [ ] ID token documentation

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Security scheme type: openIdConnect
- openIdConnectUrl discovery endpoint
- OIDC standard scopes (openid, profile, email)
- Custom OIDC scopes
- OIDC in operation security
- Swagger 2.0 ignores openIdConnect (not supported)
```

#### Story 13.3: Mutual TLS Authentication
**As a** security-conscious developer
**I want to** document mTLS requirements
**So that** clients provide client certificates

**Acceptance Criteria**:
- [ ] mutualTLS security type
- [ ] Certificate requirements documented
- [ ] Combined with other security schemes
- [ ] Per-operation mTLS requirements
- [ ] Description of certificate chain

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Security scheme type: mutualTLS
- mutualTLS in securitySchemes
- mutualTLS as operation security
- Combined mutualTLS + Bearer
- mTLS description field
- Swagger 2.0 ignores mutualTLS (not supported)
```

#### Story 13.4: Security Scheme Combinations
**As an** API designer
**I want to** combine multiple security schemes
**So that** flexible authentication is documented

**Acceptance Criteria**:
- [ ] AND combination (all required)
- [ ] OR combination (any one works)
- [ ] Mixed AND/OR combinations
- [ ] Global + operation-level security
- [ ] Optional security (empty array)

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Security AND: [{ apiKey: [], oauth2: [] }]
- Security OR: [{ apiKey: [] }, { oauth2: [] }]
- Global security inheritance
- Operation security override
- Empty security (public endpoint)
- Complex nested combinations
```

### Technical Implementation

#### OAuth2 with All Flows
```yaml
components:
  securitySchemes:
    oauth2:
      type: oauth2
      description: OAuth2 authentication
      flows:
        authorizationCode:
          authorizationUrl: https://auth.example.com/authorize
          tokenUrl: https://auth.example.com/token
          refreshUrl: https://auth.example.com/refresh
          scopes:
            read: Read access
            write: Write access
            admin: Admin access
        clientCredentials:
          tokenUrl: https://auth.example.com/token
          scopes:
            api: API access
        implicit:
          authorizationUrl: https://auth.example.com/authorize
          scopes:
            read: Read access
        password:
          tokenUrl: https://auth.example.com/token
          scopes:
            user: User access
```

#### OpenID Connect
```yaml
components:
  securitySchemes:
    openId:
      type: openIdConnect
      description: OpenID Connect authentication
      openIdConnectUrl: https://auth.example.com/.well-known/openid-configuration
```

#### Mutual TLS
```yaml
components:
  securitySchemes:
    mtls:
      type: mutualTLS
      description: Client certificate authentication required
```

#### Ruby Implementation
```ruby
module GrapeSwagger
  module OpenAPI
    class SecuritySchemeBuilder
      OAUTH2_FLOWS = %i[authorizationCode clientCredentials implicit password].freeze

      def self.build(security_config, version)
        return legacy_build(security_config) if version.swagger_2_0?

        build_openapi_3_1(security_config)
      end

      private

      def self.build_openapi_3_1(config)
        case config[:type]
        when 'oauth2'
          build_oauth2(config)
        when 'openIdConnect'
          build_openid_connect(config)
        when 'mutualTLS'
          build_mutual_tls(config)
        else
          build_basic_scheme(config)
        end
      end

      def self.build_oauth2(config)
        {
          type: 'oauth2',
          description: config[:description],
          flows: build_oauth2_flows(config[:flows])
        }.compact
      end

      def self.build_oauth2_flows(flows)
        flows.each_with_object({}) do |(flow_name, flow_config), result|
          next unless OAUTH2_FLOWS.include?(flow_name.to_sym)

          result[flow_name] = {
            authorizationUrl: flow_config[:authorization_url],
            tokenUrl: flow_config[:token_url],
            refreshUrl: flow_config[:refresh_url],
            scopes: flow_config[:scopes]
          }.compact
        end
      end

      def self.build_openid_connect(config)
        {
          type: 'openIdConnect',
          description: config[:description],
          openIdConnectUrl: config[:openid_connect_url]
        }.compact
      end

      def self.build_mutual_tls(config)
        {
          type: 'mutualTLS',
          description: config[:description]
        }.compact
      end
    end
  end
end
```

### Configuration API
```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    oauth2: {
      type: 'oauth2',
      description: 'OAuth2 authentication',
      flows: {
        authorizationCode: {
          authorization_url: 'https://auth.example.com/authorize',
          token_url: 'https://auth.example.com/token',
          refresh_url: 'https://auth.example.com/refresh',
          scopes: {
            'read' => 'Read access',
            'write' => 'Write access'
          }
        },
        clientCredentials: {
          token_url: 'https://auth.example.com/token',
          scopes: { 'api' => 'API access' }
        }
      }
    },
    openId: {
      type: 'openIdConnect',
      openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
    },
    mtls: {
      type: 'mutualTLS',
      description: 'Client certificate required'
    }
  },
  security: [
    { oauth2: ['read'] },
    { openId: [] }
  ]
)
```

### Definition of Done
- [ ] TDD: All RED tests written
- [ ] TDD: All tests GREEN
- [ ] TDD: Code refactored
- [ ] OAuth2 flows working
- [ ] OpenID Connect supported
- [ ] Mutual TLS documented
- [ ] Security combinations work
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 8
- **Estimated Hours**: 16
- **Risk Level**: Medium
- **Dependencies**: Sprints 11-12 complete

---

**Next Sprint**: Sprint 14 will implement discriminator and polymorphism improvements for better schema inheritance.
