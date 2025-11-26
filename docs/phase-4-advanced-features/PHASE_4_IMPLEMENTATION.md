# Phase 4 Implementation: Advanced Features

## Phase Status: COMPLETE

### Implementation Summary

Phase 4 implemented advanced OpenAPI 3.1.0 features including webhooks, callbacks, links, enhanced security schemes, and polymorphic schema support with discriminators. 150 new tests using strict TDD across 4 sprints.

### Sprints Completed

| Sprint | Focus | Tests | Status |
|--------|-------|-------|--------|
| Sprint 11 | Webhooks | 20 | COMPLETE |
| Sprint 12 | Callbacks & Links | 46 | COMPLETE |
| Sprint 13 | Enhanced Security | 48 | COMPLETE |
| Sprint 14 | Discriminator & Polymorphism | 36 | COMPLETE |

### Files Created

| File | Purpose | Lines |
|------|---------|-------|
| lib/grape-swagger/openapi/webhook_builder.rb | Top-level webhooks object | 173 |
| lib/grape-swagger/openapi/callback_builder.rb | Async operation callbacks with runtime expressions | 140 |
| lib/grape-swagger/openapi/link_builder.rb | Operation chaining with parameter mapping | 122 |
| lib/grape-swagger/openapi/security_scheme_builder.rb | OAuth2 flows, OpenID Connect, mTLS | 157 |
| lib/grape-swagger/openapi/discriminator_builder.rb | Polymorphic discriminator with mapping | 76 |
| lib/grape-swagger/openapi/polymorphic_schema_builder.rb | oneOf/anyOf/allOf schema composition | 82 |

### Test Results

- **150 new tests** written using TDD (RED then GREEN)
- **All tests passing** (1132 total in suite)
- **Zero Rubocop violations**
- **100% backward compatibility** with Swagger 2.0

### Key Features Delivered

#### Sprint 11: Webhooks
- Top-level `webhooks` object for async event documentation
- Request body schemas with content types
- Response status codes and schemas
- Multiple webhooks with unique event names
- Swagger 2.0 returns nil (not supported)

#### Sprint 12: Callbacks & Links
- Callbacks with runtime expressions (`{$request.body#/callbackUrl}`)
- Multiple callbacks per operation
- Callback request/response documentation
- Links with operationId and operationRef
- Parameter mapping with runtime expressions
- Request body references in links

#### Sprint 13: Enhanced Security
- OAuth2 with all four flows (authorizationCode, clientCredentials, implicit, password)
- Refresh URL support in OAuth2 flows
- Scopes with descriptions
- OpenID Connect with discovery URL
- Mutual TLS (mutualTLS) authentication
- Security scheme combinations (AND/OR)
- Swagger 2.0 backward compatibility

#### Sprint 14: Discriminator & Polymorphism
- Discriminator with propertyName
- Explicit mapping to schema refs
- Automatic ref normalization
- oneOf schema arrays with discriminator
- anyOf schema arrays with discriminator
- allOf for schema inheritance
- Swagger 2.0 discriminator (simple string format)

### Schema Examples

**Webhook:**
```yaml
# OpenAPI 3.1.0
webhooks:
  newOrder:
    post:
      summary: New order notification
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Order'
      responses:
        '200':
          description: Webhook processed
```

**Callback with Runtime Expression:**
```yaml
# OpenAPI 3.1.0
callbacks:
  onEvent:
    '{$request.body#/callbackUrl}':
      post:
        requestBody:
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Event'
```

**Link with Parameter Mapping:**
```yaml
# OpenAPI 3.1.0
links:
  GetUserById:
    operationId: getUser
    parameters:
      userId: '$response.body#/id'
```

**OAuth2 Security Scheme:**
```yaml
# OpenAPI 3.1.0
components:
  securitySchemes:
    oauth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.example.com/authorize
          tokenUrl: https://auth.example.com/token
          refreshUrl: https://auth.example.com/refresh
          scopes:
            read: Read access
            write: Write access
```

**Discriminator with Mapping:**
```yaml
# OpenAPI 3.1.0
discriminator:
  propertyName: petType
  mapping:
    dog: '#/components/schemas/Dog'
    cat: '#/components/schemas/Cat'
```

**Polymorphic oneOf:**
```yaml
# OpenAPI 3.1.0
oneOf:
  - $ref: '#/components/schemas/SuccessResponse'
  - $ref: '#/components/schemas/ErrorResponse'
discriminator:
  propertyName: status
```

### Commits

1. `feat: Implement Sprint 11: Webhooks for OpenAPI 3.1.0`
2. `feat: Implement Sprint 12: Callbacks & Links for OpenAPI 3.1.0`
3. `feat: Implement Sprint 13: Enhanced Security Models for OpenAPI 3.1.0`
4. `feat: Implement Sprint 14: Discriminator & Polymorphism for OpenAPI 3.1.0`
5. `style: Fix Rubocop violations in Phase 4 builders`

### Code Review Grades

| Sprint | Grade | Notes |
|--------|-------|-------|
| Sprint 11 | A- | Clean webhook implementation |
| Sprint 12 | B+ | Missing runtime expression validation |
| Sprint 13 | A | Complete security scheme support |
| Sprint 14 | B+ | Excellent builders, integration pending |

### Integration Notes

The Phase 4 builders are standalone utilities that follow version-aware patterns:

```ruby
# Version check pattern
return nil unless version.openapi_3_1_0?

# Swagger 2.0 backward compatibility
if version.swagger_2_0?
  return build_legacy_format(config)
end
```

Future integration points:
- WebhookBuilder → add_swagger_documentation options
- CallbackBuilder → operation-level callbacks
- LinkBuilder → response links
- SecuritySchemeBuilder → security_definitions
- DiscriminatorBuilder → entity inheritance
- PolymorphicSchemaBuilder → response schemas

### Phase 4 Completion Checklist

- [x] Webhooks documentation working
- [x] Callbacks with runtime expressions
- [x] Links for operation chaining
- [x] OAuth2 with all flows
- [x] OpenID Connect support
- [x] Mutual TLS documentation
- [x] Discriminator with mapping
- [x] oneOf/anyOf schemas
- [x] All tests passing
- [x] Documentation updated
- [x] Ready for Phase 5

---

**Phase 4 Status**: COMPLETE
**Next Phase**: Phase 5 - Production Readiness (Performance, Documentation, Release)
