# External Documentation Object

Allows referencing an external resource for extended documentation.

## Official Specification

According to the OpenAPI 3.1.0 specification, the External Documentation Object permits references to supplementary documentation resources outside the API specification itself.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `description` | string | No | ✅ | A description of the target documentation. CommonMark syntax MAY be used for rich text representation. |
| `url` | string | Yes | ✅ | The URI for the target documentation. This MUST be in the form of a URI. |

## Status

✅ **Fully Implemented**

External documentation links are supported at both the API-level and operation-level.

## Extension Support

This object MAY be extended with Specification Extensions (fields prefixed with `x-`).

## Implementation Locations

External documentation can appear at multiple levels in the OpenAPI specification:

1. **API-level** - Top-level `externalDocs` field
2. **Operation-level** - Within individual operation objects
3. **Tag-level** - Within tag objects (not yet supported)
4. **Schema-level** - Within schema objects (not yet supported)

### Currently Supported Levels

#### 1. API-Level External Docs

Configured via `add_swagger_documentation`:

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  external_docs: {
    description: 'Find more information about this API',
    url: 'https://docs.example.com/api'
  }
)
```

Generated OpenAPI output:

```json
{
  "openapi": "3.1.0",
  "info": {
    "title": "Example API"
  },
  "externalDocs": {
    "description": "Find more information about this API",
    "url": "https://docs.example.com/api"
  }
}
```

#### 2. Operation-Level External Docs

Configured via the `desc` block:

```ruby
desc 'Complex algorithm endpoint',
     external_docs: {
       description: 'Algorithm documentation',
       url: 'https://example.com/docs/algorithm'
     }
get '/calculate' do
  { result: 42 }
end
```

Generated OpenAPI output:

```json
{
  "paths": {
    "/calculate": {
      "get": {
        "summary": "Complex algorithm endpoint",
        "externalDocs": {
          "description": "Algorithm documentation",
          "url": "https://example.com/docs/algorithm"
        }
      }
    }
  }
}
```

## Examples from Demo Application

The demo application (`/demo/app/api`) demonstrates both levels:

### API-Level (root.rb)
```ruby
external_docs: {
  description: 'Find more information about grape-swagger OpenAPI 3.1.0 support',
  url: 'https://github.com/ruby-grape/grape-swagger/blob/master/docs/OPENAPI_3_1_FEATURES.md'
}
```

### Operation-Level (advanced_features_api.rb)
```ruby
desc 'Demonstrates operation-level external documentation',
     summary: 'Complex algorithm with external docs',
     external_docs: {
       description: 'Detailed algorithm documentation',
       url: 'https://example.com/docs/algorithms/scoring'
     }
```

## Test Coverage

Both levels are tested:

1. **Spec tests** - `/spec/grape-swagger/openapi/spec_builder_v3_1_spec.rb` (API-level)
2. **Integration tests** - `/spec/grape-swagger/openapi/advanced_features_spec.rb` (operation-level)
3. **Demo application** - `/demo/app/api` (both levels)

## Future Enhancements

The following levels are defined in the OpenAPI specification but not yet supported:

- [ ] Tag-level external documentation (via Tag Object's `externalDocs` field)
- [ ] Schema-level external documentation (via Schema Object's `externalDocs` field)
