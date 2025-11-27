# OpenAPI Object

The root object of the OpenAPI Description.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `openapi` | string | Yes | :white_check_mark: | Set via `openapi_version: '3.1.0'` |
| `info` | [Info Object](InfoObject.md) | Yes | :white_check_mark: | Set via `info:` option |
| `jsonSchemaDialect` | string | No | :x: | JSON Schema dialect URI |
| `servers` | [[Server Object](ServerObject.md)] | No | :white_check_mark: | Set via `servers:` option |
| `paths` | [Paths Object](PathsObject.md) | No | :white_check_mark: | Auto-generated from routes |
| `webhooks` | Map[string, [Path Item Object](PathItemObject.md)] | No | :white_check_mark: | Set via `webhooks:` option |
| `components` | [Components Object](ComponentsObject.md) | No | :white_check_mark: | Auto-generated |
| `security` | [[Security Requirement Object](SecurityRequirementObject.md)] | No | :white_check_mark: | Set via `security:` option |
| `tags` | [[Tag Object](TagObject.md)] | No | :white_check_mark: | Set via `tags:` option |
| `externalDocs` | [External Documentation Object](ExternalDocumentationObject.md) | No | :white_check_mark: | Set via `external_docs:` option |

## Usage

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  info: {
    title: 'My API',
    version: '1.0.0',
    description: 'API description',
    contact: { name: 'Support', email: 'support@example.com' },
    license: { name: 'MIT', identifier: 'MIT' }
  },
  servers: [
    { url: 'https://api.example.com', description: 'Production' }
  ],
  webhooks: {
    orderCreated: {
      method: :post,
      summary: 'Order created webhook'
    }
  },
  security: [{ api_key: [] }],
  tags: [{ name: 'users', description: 'User operations' }],
  external_docs: {
    description: 'Find more information here',
    url: 'https://example.com/docs'
  }
)
```

## Output Example

```json
{
  "openapi": "3.1.0",
  "info": {
    "title": "My API",
    "version": "1.0.0"
  },
  "servers": [...],
  "paths": {...},
  "webhooks": {...},
  "components": {...},
  "security": [...],
  "tags": [...],
  "externalDocs": {
    "description": "Find more information here",
    "url": "https://example.com/docs"
  }
}
```

## Tests

- `spec/grape-swagger/openapi/spec_builder_v3_1_spec.rb`
- `spec/openapi_v3_1/root_object_spec.rb` (TODO)

## TODO

- [ ] Add `jsonSchemaDialect` support
