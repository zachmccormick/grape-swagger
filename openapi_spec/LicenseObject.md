# License Object

License information for the exposed API.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `name` | string | Yes | :white_check_mark: | License name (e.g., "MIT") |
| `identifier` | string | No | :white_check_mark: | SPDX license identifier (3.1.0) |
| `url` | string | No | :white_check_mark: | License URL |

**Note:** `identifier` and `url` are mutually exclusive per the spec.

## Usage

```ruby
# Using SPDX identifier (OpenAPI 3.1.0)
add_swagger_documentation(
  openapi_version: '3.1.0',
  info: {
    title: 'My API',
    version: '1.0.0',
    license: {
      name: 'MIT',
      identifier: 'MIT'
    }
  }
)

# Using URL
add_swagger_documentation(
  openapi_version: '3.1.0',
  info: {
    title: 'My API',
    version: '1.0.0',
    license: {
      name: 'Apache 2.0',
      url: 'https://www.apache.org/licenses/LICENSE-2.0.html'
    }
  }
)
```

## Output Example

```json
{
  "info": {
    "license": {
      "name": "MIT",
      "identifier": "MIT"
    }
  }
}
```

## Tests

- `spec/grape-swagger/openapi/info_builder_spec.rb`

## Implementation

- `lib/grape-swagger/openapi/info_builder.rb`

## OpenAPI 3.1.0 Notes

The `identifier` field is new in OpenAPI 3.1.0 and should contain an SPDX license expression (e.g., "MIT", "Apache-2.0", "GPL-3.0-only").
