# Info Object

Provides metadata about the API.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `title` | string | Yes | :white_check_mark: | Set via `info: { title: }` |
| `summary` | string | No | :white_check_mark: | Set via `info: { summary: }` |
| `description` | string | No | :white_check_mark: | Set via `info: { description: }` |
| `termsOfService` | string | No | :white_check_mark: | Set via `info: { termsOfService: }` |
| `contact` | [Contact Object](ContactObject.md) | No | :white_check_mark: | Set via `info: { contact: }` |
| `license` | [License Object](LicenseObject.md) | No | :white_check_mark: | Set via `info: { license: }` |
| `version` | string | Yes | :white_check_mark: | Set via `doc_version:` or `info: { version: }` |

## Usage

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  info: {
    title: 'Pet Store API',
    summary: 'A sample Pet Store API',
    description: 'This is a sample server for a pet store.',
    termsOfService: 'https://example.com/terms',
    contact: {
      name: 'API Support',
      url: 'https://example.com/support',
      email: 'support@example.com'
    },
    license: {
      name: 'Apache 2.0',
      identifier: 'Apache-2.0'
    },
    version: '1.0.0'
  }
)
```

## Output Example

```json
{
  "info": {
    "title": "Pet Store API",
    "summary": "A sample Pet Store API",
    "description": "This is a sample server for a pet store.",
    "termsOfService": "https://example.com/terms",
    "contact": {
      "name": "API Support",
      "url": "https://example.com/support",
      "email": "support@example.com"
    },
    "license": {
      "name": "Apache 2.0",
      "identifier": "Apache-2.0"
    },
    "version": "1.0.0"
  }
}
```

## Tests

- `spec/grape-swagger/openapi/info_builder_spec.rb`

## Implementation

- `lib/grape-swagger/openapi/info_builder.rb`
