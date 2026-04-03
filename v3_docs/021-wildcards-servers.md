# PR 21: Wildcard Status Codes

## Overview

Adds support for wildcard response status codes (1XX, 2XX, 3XX, 4XX, 5XX) in OpenAPI 3.1.0 output. Wildcard codes allow documenting broad categories of responses alongside specific status codes, following the OpenAPI specification's support for range-based status codes.

## Changes

### 1. `wildcard_status_code?` helper (`endpoint.rb`)

A new private helper method `wildcard_status_code?(code)` detects wildcard status code patterns. It matches codes like `1XX`, `2XX`, `3XX`, `4XX`, `5XX` (case-insensitive) and the special `default` keyword.

```ruby
wildcard_status_code?('4XX')     # => true
wildcard_status_code?('5xx')     # => true
wildcard_status_code?('default') # => true
wildcard_status_code?(200)       # => false
wildcard_status_code?('200')     # => false
```

### 2. Response building updates (`endpoint.rb`)

The `success_code?` method is updated to recognize wildcard success codes (`2XX`/`2xx`) alongside numeric 2xx codes.

The `build_reference` method is updated so wildcard codes that represent success ranges (e.g., `2XX`) correctly support `is_array` wrapping, while non-success wildcards (e.g., `4XX`, `5XX`) skip array wrapping.

### 3. Wildcard codes as response keys

Wildcard codes pass through as string keys in the responses object:

```ruby
desc 'Get items',
     success: { code: 200, message: 'OK' },
     failure: [
       { code: '4XX', message: 'Client Error' },
       { code: '5XX', message: 'Server Error' }
     ]
```

Produces:

```json
{
  "responses": {
    "200": { "description": "OK" },
    "4XX": { "description": "Client Error" },
    "5XX": { "description": "Server Error" }
  }
}
```

### 4. Wildcard codes with models

Wildcard responses can include model references:

```ruby
desc 'Get items',
     success: { code: 200, message: 'OK' },
     failure: [
       { code: '4XX', message: 'Client Error', model: ErrorEntity },
       { code: '5XX', message: 'Server Error', model: ErrorEntity }
     ]
```

### 5. Mixed specific and wildcard codes

Specific status codes and wildcard ranges can coexist:

```ruby
failure: [
  { code: 400, message: 'Bad Request' },
  { code: 401, message: 'Unauthorized' },
  { code: '4XX', message: 'Other Client Errors' },
  { code: '5XX', message: 'Server Error' }
]
```

### 6. Case handling

Both uppercase (`4XX`) and lowercase (`4xx`) wildcard codes are accepted and preserved as provided.

## Test Coverage

- Basic wildcard responses (4XX, 5XX) with descriptions
- Mixed specific and wildcard responses on the same endpoint
- Wildcard responses with model/entity references
- All wildcard code types (1XX through 5XX)
- Default response combined with wildcards
- Lowercase wildcard codes (4xx, 5xx)
