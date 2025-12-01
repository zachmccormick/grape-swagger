# OpenAPI 3.1.0 Feature Coverage Matrix

This table documents **every field** from the OpenAPI 3.1.0 specification and indicates:

- ✅ = Covered/Demonstrated
- ❌ = Not covered/Not demonstrated
- 🔶 = Partial coverage

Last updated: 2025-11-26 - Verified against official OpenAPI 3.1.0 spec. Includes advanced features (cookies, deprecated
params, readOnly/writeOnly, callbacks, links, externalDocs).

---

## 1. OpenAPI Object (Root)

| Field               | Type                          | Required | Spec Tests | Demo App |
|---------------------|-------------------------------|----------|------------|----------|
| `openapi`           | string                        | Yes      | ✅          | ✅        |
| `info`              | Info Object                   | Yes      | ✅          | ✅        |
| `jsonSchemaDialect` | string                        | No       | ❌          | ❌        |
| `servers`           | [Server Object]               | No       | ✅          | ✅        |
| `paths`             | Paths Object                  | No       | ✅          | ✅        |
| `webhooks`          | Map[string, Path Item Object] | No       | ✅          | ✅        |
| `components`        | Components Object             | No       | ✅          | ✅        |
| `security`          | [Security Requirement Object] | No       | ✅          | ✅        |
| `tags`              | [Tag Object]                  | No       | ✅          | ✅        |
| `externalDocs`      | External Documentation Object | No       | ✅          | ✅        |

---

## 2. Info Object

| Field            | Type           | Required | Spec Tests | Demo App |
|------------------|----------------|----------|------------|----------|
| `title`          | string         | Yes      | ✅          | ✅        |
| `summary`        | string         | No       | ✅          | ✅        |
| `description`    | string         | No       | ✅          | ✅        |
| `termsOfService` | string         | No       | ✅          | ✅        |
| `contact`        | Contact Object | No       | ✅          | ✅        |
| `license`        | License Object | No       | ✅          | ✅        |
| `version`        | string         | Yes      | ✅          | ✅        |

---

## 3. Contact Object

| Field   | Type   | Required | Spec Tests | Demo App |
|---------|--------|----------|------------|----------|
| `name`  | string | No       | ✅          | ✅        |
| `url`   | string | No       | ✅          | ✅        |
| `email` | string | No       | ✅          | ✅        |

---

## 4. License Object

| Field        | Type   | Required | Spec Tests | Demo App |
|--------------|--------|----------|------------|----------|
| `name`       | string | Yes      | ✅          | ✅        |
| `identifier` | string | No       | ✅          | ✅        |
| `url`        | string | No       | ✅          | ❌        |

---

## 5. Server Object

| Field         | Type                                | Required | Spec Tests | Demo App |
|---------------|-------------------------------------|----------|------------|----------|
| `url`         | string                              | Yes      | ✅          | ✅        |
| `description` | string                              | No       | ✅          | ✅        |
| `variables`   | Map[string, Server Variable Object] | No       | ✅          | ✅        |

---

## 6. Server Variable Object

| Field         | Type     | Required | Spec Tests | Demo App |
|---------------|----------|----------|------------|----------|
| `enum`        | [string] | No       | ✅          | ✅        |
| `default`     | string   | Yes      | ✅          | ✅        |
| `description` | string   | No       | ✅          | ✅        |

---

## 7. Paths Object

| Field Pattern | Type             | Required | Spec Tests | Demo App |
|---------------|------------------|----------|------------|----------|
| `/{path}`     | Path Item Object | No       | ✅          | ✅        |
| `^x-`         | Any              | No       | 🔶         | ❌        |

**Note**: Specification Extensions (`^x-`) are tested in Swagger 2.0 tests but not specifically verified for OpenAPI
3.1.0 (though the same extension mechanism is used for all versions).

---

## 8. Path Item Object

| Field         | Type                                   | Required | Spec Tests | Demo App |
|---------------|----------------------------------------|----------|------------|----------|
| `$ref`        | string                                 | No       | ❌          | ❌        |
| `summary`     | string                                 | No       | ❌          | ❌        |
| `description` | string                                 | No       | ❌          | ❌        |
| `get`         | Operation Object                       | No       | ✅          | ✅        |
| `put`         | Operation Object                       | No       | ✅          | ✅        |
| `post`        | Operation Object                       | No       | ✅          | ✅        |
| `delete`      | Operation Object                       | No       | ✅          | ✅        |
| `options`     | Operation Object                       | No       | ✅          | ❌        |
| `head`        | Operation Object                       | No       | ✅          | ❌        |
| `patch`       | Operation Object                       | No       | ✅          | ✅        |
| `trace`       | Operation Object                       | No       | ❌          | ❌        |
| `servers`     | [Server Object]                        | No       | ❌          | ❌        |
| `parameters`  | [Parameter Object \| Reference Object] | No       | ❌          | ❌        |

---

## 9. Operation Object

| Field          | Type                          | Required | Spec Tests | Demo App |
|----------------|-------------------------------|----------|------------|----------|
| `tags`         | [string]                      | No       | ✅          | ✅        |
| `summary`      | string                        | No       | ✅          | ✅        |
| `description`  | string                        | No       | ✅          | ✅        |
| `externalDocs` | External Documentation Object | No       | ✅          | ✅        |
| `operationId`  | string                        | No       | ✅          | ✅        |
| `parameters`   | [Parameter Object]            | No       | ✅          | ✅        |
| `requestBody`  | Request Body Object           | No       | ✅          | ✅        |
| `responses`    | Responses Object              | Yes      | ✅          | ✅        |
| `callbacks`    | Map[string, Callback Object]  | No       | ✅          | ✅        |
| `deprecated`   | boolean                       | No       | ✅          | ✅        |
| `security`     | [Security Requirement Object] | No       | ✅          | ✅        |
| `servers`      | [Server Object]               | No       | ❌          | ❌        |

---

## 10. External Documentation Object

| Field         | Type   | Required | Spec Tests | Demo App |
|---------------|--------|----------|------------|----------|
| `description` | string | No       | ✅          | ✅        |
| `url`         | string | Yes      | ✅          | ✅        |

---

## 11. Parameter Object

| Field             | Type                           | Required | Spec Tests | Demo App |
|-------------------|--------------------------------|----------|------------|----------|
| `name`            | string                         | Yes      | ✅          | ✅        |
| `in`              | string                         | Yes      | ✅          | ✅        |
| `description`     | string                         | No       | ✅          | ✅        |
| `required`        | boolean                        | No       | ✅          | ✅        |
| `deprecated`      | boolean                        | No       | ✅          | ✅        |
| `allowEmptyValue` | boolean                        | No       | ✅          | ✅        |
| `style`           | string                         | No       | ✅          | ✅        |
| `explode`         | boolean                        | No       | ✅          | ✅        |
| `allowReserved`   | boolean                        | No       | ✅          | ✅        |
| `schema`          | Schema Object                  | No       | ✅          | ✅        |
| `example`         | any                            | No       | ✅          | ✅        |
| `examples`        | Map[string, Example Object]    | No       | ❌          | ❌        |
| `content`         | Map[string, Media Type Object] | No       | ❌          | ❌        |

### Parameter Locations (`in` values)

| Location | Spec Tests | Demo App |
|----------|------------|----------|
| `query`  | ✅          | ✅        |
| `path`   | ✅          | ✅        |
| `header` | ✅          | ✅        |
| `cookie` | ✅          | ✅        |

---

## 12. Request Body Object

| Field         | Type                           | Required | Spec Tests | Demo App |
|---------------|--------------------------------|----------|------------|----------|
| `description` | string                         | No       | ✅          | ❌        |
| `content`     | Map[string, Media Type Object] | Yes      | ✅          | ✅        |
| `required`    | boolean                        | No       | ✅          | ✅        |

---

## 13. Media Type Object

| Field      | Type                                            | Required | Spec Tests | Demo App |
|------------|-------------------------------------------------|----------|------------|----------|
| `schema`   | Schema Object                                   | No       | ✅          | ✅        |
| `example`  | any                                             | No       | ✅          | ✅        |
| `examples` | Map[string, Example Object \| Reference Object] | No       | ✅          | ✅        |
| `encoding` | Map[string, Encoding Object]                    | No       | ✅          | ✅        |

---

## 14. Encoding Object

| Field           | Type                       | Required | Spec Tests | Demo App |
|-----------------|----------------------------|----------|------------|----------|
| `contentType`   | string                     | No       | ✅          | ✅        |
| `headers`       | Map[string, Header Object] | No       | ✅          | ❌        |
| `style`         | string                     | No       | ✅          | ❌        |
| `explode`       | boolean                    | No       | ✅          | ❌        |
| `allowReserved` | boolean                    | No       | ✅          | ❌        |

---

## 15. Responses Object

| Field                | Type            | Required | Spec Tests | Demo App |
|----------------------|-----------------|----------|------------|----------|
| `default`            | Response Object | No       | ✅          | ✅        |
| `{HTTP Status Code}` | Response Object | No       | ✅          | ✅        |

### Tested Status Codes

| Status Code    | Spec Tests | Demo App |
|----------------|------------|----------|
| 200            | ✅          | ✅        |
| 201            | ✅          | ✅        |
| 202            | ✅          | ✅        |
| 204            | ✅          | ✅        |
| 400            | ✅          | ✅        |
| 401            | ✅          | ✅        |
| 403            | ✅          | ✅        |
| 404            | ✅          | ✅        |
| 409            | ✅          | ✅        |
| 413            | ❌          | ✅        |
| 415            | ❌          | ✅        |
| 422            | ✅          | ✅        |
| 429            | ❌          | ✅        |
| 500            | ✅          | ✅        |
| 4XX (wildcard) | ❌          | ❌        |
| 5XX (wildcard) | ❌          | ❌        |

---

## 16. Response Object

| Field         | Type                           | Required | Spec Tests | Demo App |
|---------------|--------------------------------|----------|------------|----------|
| `description` | string                         | Yes      | ✅          | ✅        |
| `headers`     | Map[string, Header Object]     | No       | ✅          | ❌        |
| `content`     | Map[string, Media Type Object] | No       | ✅          | ✅        |
| `links`       | Map[string, Link Object]       | No       | ✅          | ✅        |

---

## 17. Callback Object

### Patterned Fields

| Field Pattern  | Type                                 | Required | Spec Tests | Demo App |
|----------------|--------------------------------------|----------|------------|----------|
| `{expression}` | Path Item Object \| Reference Object | N/A      | ✅          | ✅        |

### Specification Extensions

| Field Pattern | Type | Required | Spec Tests | Demo App |
|---------------|------|----------|------------|----------|
| `^x-`         | Any  | No       | ✅          | ❌        |

### Runtime Expressions Tested

| Expression               | Spec Tests | Demo App |
|--------------------------|------------|----------|
| `{$url}`                 | ✅          | ❌        |
| `{$method}`              | ✅          | ❌        |
| `{$request.body#/path}`  | ✅          | ✅        |
| `{$request.query.param}` | ✅          | ❌        |
| `{$request.header.name}` | ✅          | ❌        |
| `{$response.body#/path}` | ✅          | ✅        |

---

## 18. Example Object

| Field           | Type   | Required | Spec Tests | Demo App |
|-----------------|--------|----------|------------|----------|
| `summary`       | string | No       | ✅          | ❌        |
| `description`   | string | No       | ✅          | ❌        |
| `value`         | any    | No       | ✅          | ✅        |
| `externalValue` | string | No       | ❌          | ❌        |

**Note:** `value` and `externalValue` are mutually exclusive per the OpenAPI 3.1.0 specification.

---

## 19. Link Object

| Field          | Type             | Required | Spec Tests | Demo App |
|----------------|------------------|----------|------------|----------|
| `operationRef` | string           | No       | ✅          | ❌        |
| `operationId`  | string           | No       | ✅          | ✅        |
| `parameters`   | Map[string, any] | No       | ✅          | ✅        |
| `requestBody`  | any              | No       | ✅          | ✅        |
| `description`  | string           | No       | ✅          | ✅        |
| `server`       | Server Object    | No       | ✅          | ❌        |

---

## 20. Header Object

| Field             | Type                           | Required | Spec Tests | Demo App |
|-------------------|--------------------------------|----------|------------|----------|
| `description`     | string                         | No       | ✅          | ✅        |
| `required`        | boolean                        | No       | ✅          | ✅        |
| `deprecated`      | boolean                        | No       | ✅          | ✅        |
| `allowEmptyValue` | boolean                        | No       | ❌          | ❌        |
| `style`           | string                         | No       | ✅          | ❌        |
| `explode`         | boolean                        | No       | ❌          | ❌        |
| `allowReserved`   | boolean                        | No       | ❌          | ❌        |
| `schema`          | Schema Object                  | No       | ✅          | ✅        |
| `example`         | any                            | No       | ✅          | ✅        |
| `examples`        | Map[string, Example Object]    | No       | ❌          | ❌        |
| `content`         | Map[string, Media Type Object] | No       | ❌          | ❌        |

---

## 21. Tag Object

| Field          | Type                          | Required | Spec Tests | Demo App |
|----------------|-------------------------------|----------|------------|----------|
| `name`         | string                        | Yes      | ✅          | ✅        |
| `description`  | string                        | No       | ✅          | ✅        |
| `externalDocs` | External Documentation Object | No       | ❌          | ❌        |

---

## 22. Reference Object

| Field         | Type   | Required | Spec Tests | Demo App |
|---------------|--------|----------|------------|----------|
| `$ref`        | string | Yes      | ✅          | ✅        |
| `summary`     | string | No       | ❌          | ❌        |
| `description` | string | No       | ❌          | ❌        |

### Reference Target Types

| Target                                | Spec Tests | Demo App |
|---------------------------------------|------------|----------|
| `#/components/schemas/{name}`         | ✅          | ✅        |
| `#/components/responses/{name}`       | ✅          | 🔶        |
| `#/components/parameters/{name}`      | ✅          | 🔶        |
| `#/components/examples/{name}`        | ❌          | ❌        |
| `#/components/requestBodies/{name}`   | ❌          | ❌        |
| `#/components/headers/{name}`         | ✅          | 🔶        |
| `#/components/securitySchemes/{name}` | ✅          | ✅        |
| `#/components/links/{name}`           | ❌          | ❌        |
| `#/components/callbacks/{name}`       | ❌          | ❌        |
| `#/components/pathItems/{name}`       | ❌          | ❌        |
| External URI references               | ✅          | ❌        |

---

## 23. Schema Object

### Core JSON Schema Keywords

| Field         | Type               | Spec Tests | Demo App |
|---------------|--------------------|------------|----------|
| `type`        | string \| [string] | ✅          | ✅        |
| `format`      | string             | ✅          | ✅        |
| `title`       | string             | ❌          | ❌        |
| `description` | string             | ✅          | ✅        |
| `default`     | any                | ✅          | ✅        |
| `enum`        | [any]              | ✅          | ✅        |
| `const`       | any                | ✅          | ❌        |
| `examples`    | [any]              | 🔶         | ❌        |

### Object Keywords

| Field                  | Type                  | Spec Tests | Demo App |
|------------------------|-----------------------|------------|----------|
| `properties`           | Map[string, Schema]   | ✅          | ✅        |
| `required`             | [string]              | ✅          | ✅        |
| `additionalProperties` | boolean \| Schema     | ✅          | ❌        |
| `minProperties`        | integer               | ❌          | ❌        |
| `maxProperties`        | integer               | ❌          | ❌        |
| `patternProperties`    | Map[string, Schema]   | ❌          | ❌        |
| `propertyNames`        | Schema                | ❌          | ❌        |
| `dependentRequired`    | Map[string, [string]] | ❌          | ❌        |

### Array Keywords

| Field         | Type     | Spec Tests | Demo App |
|---------------|----------|------------|----------|
| `items`       | Schema   | ✅          | ✅        |
| `prefixItems` | [Schema] | ❌          | ❌        |
| `minItems`    | integer  | ❌          | ❌        |
| `maxItems`    | integer  | ❌          | ❌        |
| `uniqueItems` | boolean  | ❌          | ❌        |
| `contains`    | Schema   | ❌          | ❌        |
| `minContains` | integer  | ❌          | ❌        |
| `maxContains` | integer  | ❌          | ❌        |

### String Keywords

| Field       | Type    | Spec Tests | Demo App |
|-------------|---------|------------|----------|
| `minLength` | integer | ✅          | ❌        |
| `maxLength` | integer | ✅          | ❌        |
| `pattern`   | string  | ✅          | ✅        |

### Numeric Keywords

| Field              | Type   | Spec Tests | Demo App |
|--------------------|--------|------------|----------|
| `minimum`          | number | ✅          | ✅        |
| `maximum`          | number | ✅          | ✅        |
| `exclusiveMinimum` | number | ❌          | ❌        |
| `exclusiveMaximum` | number | ❌          | ❌        |
| `multipleOf`       | number | ❌          | ❌        |

### Schema Composition

| Field   | Type     | Spec Tests | Demo App |
|---------|----------|------------|----------|
| `allOf` | [Schema] | ✅          | ✅        |
| `oneOf` | [Schema] | ✅          | ✅        |
| `anyOf` | [Schema] | ✅          | ❌        |
| `not`   | Schema   | ❌          | ❌        |

### Conditional Keywords

| Field              | Type                | Spec Tests | Demo App |
|--------------------|---------------------|------------|----------|
| `if`               | Schema              | ✅          | ❌        |
| `then`             | Schema              | ✅          | ❌        |
| `else`             | Schema              | ✅          | ❌        |
| `dependentSchemas` | Map[string, Schema] | ✅          | ❌        |

### Unevaluated Keywords

| Field                   | Type              | Spec Tests | Demo App |
|-------------------------|-------------------|------------|----------|
| `unevaluatedItems`      | Schema \| boolean | ❌          | ❌        |
| `unevaluatedProperties` | Schema \| boolean | ❌          | ❌        |

### JSON Schema Metadata

| Field            | Type                | Spec Tests | Demo App |
|------------------|---------------------|------------|----------|
| `$id`            | string              | ❌          | ❌        |
| `$schema`        | string              | ❌          | ❌        |
| `$ref`           | string              | ✅          | ✅        |
| `$anchor`        | string              | ❌          | ❌        |
| `$dynamicAnchor` | string              | ❌          | ❌        |
| `$dynamicRef`    | string              | ❌          | ❌        |
| `$defs`          | Map[string, Schema] | ❌          | ❌        |
| `$comment`       | string              | ❌          | ❌        |

### Content Keywords (OpenAPI 3.1.0)

| Field              | Type   | Spec Tests | Demo App |
|--------------------|--------|------------|----------|
| `contentMediaType` | string | ✅          | ✅        |
| `contentEncoding`  | string | ✅          | ✅        |
| `contentSchema`    | Schema | ❌          | ❌        |

### Format Values

| Format      | Spec Tests | Demo App |
|-------------|------------|----------|
| `int32`     | ✅          | ✅        |
| `int64`     | ✅          | ❌        |
| `float`     | ✅          | ❌        |
| `double`    | ✅          | ❌        |
| `byte`      | ✅          | ✅        |
| `binary`    | ✅          | ✅        |
| `date`      | ✅          | ❌        |
| `date-time` | ✅          | ✅        |
| `password`  | ✅          | ❌        |
| `email`     | ✅          | ✅        |
| `uri`       | ✅          | ✅        |
| `uuid`      | ✅          | ❌        |
| `hostname`  | ✅          | ❌        |
| `ipv4`      | ✅          | ❌        |
| `ipv6`      | ✅          | ❌        |

### OpenAPI Extensions

| Field                     | Type                          | Spec Tests | Demo App |
|---------------------------|-------------------------------|------------|----------|
| `discriminator`           | Discriminator Object          | ✅          | ✅        |
| `xml`                     | XML Object                    | ❌          | ❌        |
| `externalDocs`            | External Documentation Object | ❌          | ❌        |
| `deprecated`              | boolean                       | ✅          | ✅        |
| `nullable` (3.0 style)    | boolean                       | ✅          | ✅        |
| Type arrays (3.1.0 style) | [string]                      | ✅          | ✅        |
| `readOnly`                | boolean                       | ✅          | ✅        |
| `writeOnly`               | boolean                       | ✅          | ✅        |

---

## 24. Discriminator Object

| Field          | Type                | Required | Spec Tests | Demo App |
|----------------|---------------------|----------|------------|----------|
| `propertyName` | string              | Yes      | ✅          | ✅        |
| `mapping`      | Map[string, string] | No       | ✅          | ❌        |

---

## 25. XML Object

| Field       | Type    | Required | Spec Tests | Demo App |
|-------------|---------|----------|------------|----------|
| `name`      | string  | No       | ❌          | ❌        |
| `namespace` | string  | No       | ❌          | ❌        |
| `prefix`    | string  | No       | ❌          | ❌        |
| `attribute` | boolean | No       | ❌          | ❌        |
| `wrapped`   | boolean | No       | ❌          | ❌        |

---

## 26. Security Scheme Object

### Common Fields

| Field         | Type   | Required | Spec Tests | Demo App |
|---------------|--------|----------|------------|----------|
| `type`        | string | Yes      | ✅          | ✅        |
| `description` | string | No       | ✅          | ✅        |

### Type: `apiKey`

| Field  | Type   | Required | Spec Tests | Demo App |
|--------|--------|----------|------------|----------|
| `name` | string | Yes      | ✅          | ✅        |
| `in`   | string | Yes      | ✅          | ✅        |

### `in` Values for apiKey

| Value    | Spec Tests | Demo App |
|----------|------------|----------|
| `query`  | ✅          | ❌        |
| `header` | ✅          | ✅        |
| `cookie` | ✅          | ❌        |

### Type: `http`

| Field          | Type   | Required | Spec Tests | Demo App |
|----------------|--------|----------|------------|----------|
| `scheme`       | string | Yes      | ✅          | ✅        |
| `bearerFormat` | string | No       | ✅          | ✅        |

### `scheme` Values

| Value           | Spec Tests | Demo App |
|-----------------|------------|----------|
| `basic`         | ✅          | ❌        |
| `bearer`        | ✅          | ✅        |
| `digest`        | ❌          | ❌        |
| `hoba`          | ❌          | ❌        |
| `mutual`        | ❌          | ❌        |
| `negotiate`     | ❌          | ❌        |
| `oauth`         | ❌          | ❌        |
| `scram-sha-1`   | ❌          | ❌        |
| `scram-sha-256` | ❌          | ❌        |
| `vapid`         | ❌          | ❌        |

### Type: `oauth2`

| Field   | Type               | Required | Spec Tests | Demo App |
|---------|--------------------|----------|------------|----------|
| `flows` | OAuth Flows Object | Yes      | ✅          | ✅        |

### Type: `openIdConnect`

| Field              | Type   | Required | Spec Tests | Demo App |
|--------------------|--------|----------|------------|----------|
| `openIdConnectUrl` | string | Yes      | ✅          | ✅        |

### Type: `mutualTLS`

| Field                  | Type | Required | Spec Tests | Demo App |
|------------------------|------|----------|------------|----------|
| (no additional fields) | -    | -        | ✅          | ✅        |

---

## 27. OAuth Flows Object

| Field               | Type              | Required | Spec Tests | Demo App |
|---------------------|-------------------|----------|------------|----------|
| `implicit`          | OAuth Flow Object | No       | ✅          | ❌        |
| `password`          | OAuth Flow Object | No       | ✅          | ❌        |
| `clientCredentials` | OAuth Flow Object | No       | ✅          | ✅        |
| `authorizationCode` | OAuth Flow Object | No       | ✅          | ✅        |

---

## 28. OAuth Flow Object

### Implicit Flow

| Field              | Type                | Required | Spec Tests | Demo App |
|--------------------|---------------------|----------|------------|----------|
| `authorizationUrl` | string              | Yes      | ✅          | ❌        |
| `refreshUrl`       | string              | No       | ✅          | ❌        |
| `scopes`           | Map[string, string] | Yes      | ✅          | ❌        |

### Password Flow

| Field        | Type                | Required | Spec Tests | Demo App |
|--------------|---------------------|----------|------------|----------|
| `tokenUrl`   | string              | Yes      | ✅          | ❌        |
| `refreshUrl` | string              | No       | ✅          | ❌        |
| `scopes`     | Map[string, string] | Yes      | ✅          | ❌        |

### Client Credentials Flow

| Field        | Type                | Required | Spec Tests | Demo App |
|--------------|---------------------|----------|------------|----------|
| `tokenUrl`   | string              | Yes      | ✅          | ✅        |
| `refreshUrl` | string              | No       | ✅          | ❌        |
| `scopes`     | Map[string, string] | Yes      | ✅          | ✅        |

### Authorization Code Flow

| Field              | Type                | Required | Spec Tests | Demo App |
|--------------------|---------------------|----------|------------|----------|
| `authorizationUrl` | string              | Yes      | ✅          | ✅        |
| `tokenUrl`         | string              | Yes      | ✅          | ✅        |
| `refreshUrl`       | string              | No       | ✅          | ✅        |
| `scopes`           | Map[string, string] | Yes      | ✅          | ✅        |

---

## 29. Security Requirement Object

| Field           | Type     | Required | Spec Tests | Demo App |
|-----------------|----------|----------|------------|----------|
| `{scheme_name}` | [string] | N/A      | ✅          | ✅        |

### Security Patterns

| Pattern                  | Spec Tests | Demo App |
|--------------------------|------------|----------|
| Single scheme            | ✅          | ✅        |
| Multiple schemes (AND)   | ✅          | ✅        |
| Alternative schemes (OR) | ✅          | ✅        |
| Empty security `[]`      | ✅          | ✅        |
| OAuth2 with scopes       | ✅          | ✅        |

---

## 30. Components Object

| Field             | Type                                | Required | Spec Tests | Demo App |
|-------------------|-------------------------------------|----------|------------|----------|
| `schemas`         | Map[string, Schema Object]          | No       | ✅          | ✅        |
| `responses`       | Map[string, Response Object]        | No       | ✅          | ✅        |
| `parameters`      | Map[string, Parameter Object]       | No       | ✅          | ✅        |
| `examples`        | Map[string, Example Object]         | No       | ✅          | ❌        |
| `requestBodies`   | Map[string, Request Body Object]    | No       | ✅          | ❌        |
| `headers`         | Map[string, Header Object]          | No       | ✅          | ✅        |
| `securitySchemes` | Map[string, Security Scheme Object] | No       | ✅          | ✅        |
| `links`           | Map[string, Link Object]            | No       | ✅          | ❌        |
| `callbacks`       | Map[string, Callback Object]        | No       | ✅          | ❌        |
| `pathItems`       | Map[string, Path Item Object]       | No       | ❌          | ❌        |

---

## 31. Webhook Object (OpenAPI 3.1.0)

| Field      | Type                          | Required | Spec Tests | Demo App |
|------------|-------------------------------|----------|------------|----------|
| `webhooks` | Map[string, Path Item Object] | No       | ✅          | ✅        |

### Webhook Features

| Feature        | Spec Tests | Demo App |
|----------------|------------|----------|
| Webhook naming | ✅          | ✅        |
| POST method    | ✅          | ✅        |
| GET method     | ✅          | ❌        |
| requestBody    | ✅          | ✅        |
| responses      | ✅          | ✅        |
| summary        | ✅          | ✅        |
| description    | ✅          | ✅        |
| Inline schemas | ✅          | ✅        |
| $ref schemas   | ✅          | ❌        |

---

## Summary Statistics

### Overall Coverage

| Category                      | Total Fields | Spec Tests | Demo App |
|-------------------------------|--------------|------------|----------|
| OpenAPI Object                | 10           | 8 (80%)    | 8 (80%)  |
| Info Object                   | 7            | 7 (100%)   | 6 (86%)  |
| Contact Object                | 3            | 3 (100%)   | 3 (100%) |
| License Object                | 3            | 3 (100%)   | 2 (67%)  |
| Server Object                 | 3            | 3 (100%)   | 3 (100%) |
| Server Variable Object        | 3            | 3 (100%)   | 3 (100%) |
| Path Item Object              | 13           | 7 (54%)    | 4 (31%)  |
| Operation Object              | 12           | 10 (83%)   | 9 (75%)  |
| External Documentation Object | 2            | 0 (0%)     | 0 (0%)   |
| Parameter Object              | 13           | 11 (85%)   | 11 (85%) |
| Request Body Object           | 3            | 3 (100%)   | 2 (67%)  |
| Media Type Object             | 4            | 4 (100%)   | 3 (75%)  |
| Encoding Object               | 5            | 5 (100%)   | 0 (0%)   |
| Responses Object              | 2            | 2 (100%)   | 1 (50%)  |
| Response Object               | 4            | 4 (100%)   | 2 (50%)  |
| Callback Object               | 2            | 2 (100%)   | 1 (50%)  |
| Example Object                | 4            | 3 (75%)    | 1 (25%)  |
| Link Object                   | 6            | 6 (100%)   | 0 (0%)   |
| Header Object                 | 11           | 6 (55%)    | 0 (0%)   |
| Tag Object                    | 3            | 2 (67%)    | 2 (67%)  |
| Reference Object              | 3            | 1 (33%)    | 1 (33%)  |
| Schema Object (Core)          | 8            | 7 (88%)    | 6 (75%)  |
| Schema Object (Object)        | 8            | 3 (38%)    | 2 (25%)  |
| Schema Object (Array)         | 8            | 1 (13%)    | 1 (13%)  |
| Schema Object (String)        | 3            | 3 (100%)   | 1 (33%)  |
| Schema Object (Numeric)       | 5            | 2 (40%)    | 2 (40%)  |
| Schema Object (Composition)   | 4            | 3 (75%)    | 2 (50%)  |
| Schema Object (Conditional)   | 4            | 4 (100%)   | 0 (0%)   |
| Schema Object (Metadata)      | 8            | 1 (13%)    | 1 (13%)  |
| Schema Object (Content)       | 3            | 2 (67%)    | 2 (67%)  |
| Discriminator Object          | 2            | 2 (100%)   | 1 (50%)  |
| XML Object                    | 5            | 0 (0%)     | 0 (0%)   |
| Security Scheme Object        | 10           | 10 (100%)  | 7 (70%)  |
| OAuth Flows Object            | 4            | 4 (100%)   | 2 (50%)  |
| OAuth Flow Object             | 4            | 4 (100%)   | 3 (75%)  |
| Security Requirement Object   | 1            | 1 (100%)   | 1 (100%) |
| Components Object             | 10           | 9 (90%)    | 2 (20%)  |
| Webhook Object                | 1            | 1 (100%)   | 1 (100%) |

### Feature Categories

| Category                            | Spec Coverage     | Demo Coverage      |
|-------------------------------------|-------------------|--------------------|
| **Core Structure**                  | ✅ Excellent       | ✅ Excellent        |
| **Info & Contact**                  | ✅ Complete        | ✅ Complete         |
| **Servers**                         | ✅ Complete        | ✅ Complete         |
| **Paths & Operations**              | ✅ Excellent       | ✅ Good             |
| **Parameters**                      | ✅ Excellent       | ✅ Good             |
| **Request/Response Bodies**         | ✅ Complete        | ✅ Good             |
| **Security Schemes**                | ✅ Complete        | ✅ Excellent        |
| **OAuth2 Flows**                    | ✅ Complete        | ✅ Good             |
| **Schema Types**                    | ✅ Good            | ✅ Good             |
| **Schema Validation**               | 🔶 Partial        | 🔶 Partial         |
| **Composition (allOf/oneOf/anyOf)** | ✅ Excellent       | ✅ Good             |
| **Polymorphism/Discriminator**      | ✅ Complete        | ✅ Demonstrated     |
| **Nullable Types (3.1.0)**          | ✅ Complete        | ✅ Demonstrated     |
| **Binary/Content Encoding**         | ✅ Complete        | ✅ Demonstrated     |
| **Examples**                        | ✅ Good            | ✅ Good             |
| **Webhooks (3.1.0)**                | ✅ Complete        | ✅ Demonstrated     |
| **Callbacks**                       | ✅ Complete        | ✅ Demonstrated     |
| **Links**                           | ✅ Complete        | ✅ Demonstrated     |
| **External Docs**                   | ✅ Complete        | ✅ Demonstrated     |
| **XML**                             | ❌ Not implemented | ❌ Not demonstrated |
| **Reusable Components**             | ✅ Good (params, responses, headers) | 🔶 Partial         |

---

## Not Implemented Features

The following features are documented in OpenAPI 3.1.0 but not currently supported:

### High Priority (Commonly Used)

- Reusable components for examples, requestBodies (responses, parameters, headers now supported via DSL)
- Header parameter examples in demo

### Medium Priority

- Path Item `$ref`, `summary`, `description`
- Operation-level `servers`
- Parameter `examples` (multiple)
- Schema `minLength`, `maxLength`, `minItems`, `maxItems`
- Schema `exclusiveMinimum`, `exclusiveMaximum`
- `not` composition
- Reference `summary` and `description` overrides

### Low Priority (Advanced/Rare)

- `jsonSchemaDialect`
- `trace` HTTP method
- XML Object
- Schema `$id`, `$schema`, `$anchor`, `$dynamicAnchor`, `$dynamicRef`
- Schema `prefixItems`, `contains`, `minContains`, `maxContains`
- Schema `unevaluatedItems`, `unevaluatedProperties`
- Schema `patternProperties`, `propertyNames`, `dependentRequired`
- HTTP auth schemes beyond basic/bearer
- Component `pathItems` (3.1.0)

---

## Test Coverage by File

| Test File                            | Object Types Covered                                                                                   |
|--------------------------------------|--------------------------------------------------------------------------------------------------------|
| `info_builder_spec.rb`               | Info, Contact, License                                                                                 |
| `servers_builder_spec.rb`            | Server, Server Variable                                                                                |
| `security_scheme_builder_spec.rb`    | Security Scheme, OAuth Flows, OAuth Flow                                                               |
| `security_integration_spec.rb`       | Security Requirement                                                                                   |
| `request_body_builder_spec.rb`       | Request Body, Media Type                                                                               |
| `response_content_builder_spec.rb`   | Response, Media Type, Example                                                                          |
| `parameter_schema_wrapper_spec.rb`   | Parameter, Schema                                                                                      |
| `polymorphic_schema_builder_spec.rb` | Schema (oneOf, anyOf, allOf)                                                                           |
| `discriminator_builder_spec.rb`      | Discriminator                                                                                          |
| `nullable_type_handler_spec.rb`      | Schema (nullable/type arrays)                                                                          |
| `type_mapper_spec.rb`                | Schema (format, type mapping)                                                                          |
| `webhook_builder_spec.rb`            | Webhook, Path Item                                                                                     |
| `callback_builder_spec.rb`           | Callback                                                                                               |
| `link_builder_spec.rb`               | Link                                                                                                   |
| `components_builder_spec.rb`         | Components                                                                                             |
| `encoding_builder_spec.rb`           | Encoding                                                                                               |
| `conditional_schema_builder_spec.rb` | Schema (if/then/else)                                                                                  |
| `version_spec.rb`                    | OpenAPI (version handling)                                                                             |
| `integration_spec.rb`                | End-to-end coverage                                                                                    |
| `advanced_features_spec.rb`          | Cookie params, deprecated params, readOnly/writeOnly, externalDocs, callbacks, links, default response |

---

*Generated from exhaustive analysis of OpenAPI 3.1.0 specification, 49 test files (520+ tests), and demo application
with 9 API modules.*
