# PR 19: Advanced Parameter Features

## Overview

Extends `parse_params.rb` with support for additional OpenAPI 3.1.0 documentation keys: `readOnly`/`writeOnly`, `title`, `not` (JSON Schema constraint), `minProperties`/`maxProperties`, `externalDocs`, `content` (alternative to schema for complex serialization), and `$ref` summary/description overrides.

## Changes

### 1. Reference Object Overrides (`parse_params.rb`)

OpenAPI 3.1.0 allows `summary` and `description` overrides on `$ref` objects. The existing `ref` handling is extended with `ref_summary` and `ref_description` keys:

```ruby
params do
  optional :page, type: Integer, documentation: {
    ref: '#/components/parameters/PageParam',
    ref_summary: 'Custom summary',
    ref_description: 'Override description for this endpoint'
  }
end
# => { '$ref' => '#/components/parameters/PageParam',
#      summary: 'Custom summary',
#      description: 'Override description for this endpoint' }
```

### 2. Deprecated Parameters (`parse_params.rb`)

```ruby
params do
  optional :q, type: String, documentation: { deprecated: true }
end
# => { deprecated: true }
```

### 3. readOnly / writeOnly (`parse_params.rb`)

```ruby
params do
  requires :id, type: Integer, documentation: { read_only: true }
  requires :password, type: String, documentation: { write_only: true }
end
# => { readOnly: true } / { writeOnly: true }
```

### 4. Title (`parse_params.rb`)

```ruby
params do
  requires :email, type: String, documentation: { title: 'Email Address' }
end
# => { title: 'Email Address' }
```

### 5. Not Constraint (`parse_params.rb`)

Supports inline hash schemas, string/symbol schema references, and complex constraints:

```ruby
# Inline schema
params do
  requires :value, type: String, documentation: {
    not: { type: 'string', enum: %w[forbidden blocked] }
  }
end
# => { not: { type: 'string', enum: ['forbidden', 'blocked'] } }

# Schema reference (string or symbol)
params do
  requires :config, type: Hash, documentation: { not: 'DeprecatedConfig' }
end
# => { not: { '$ref' => '#/components/schemas/DeprecatedConfig' } }
```

### 6. minProperties / maxProperties (`parse_params.rb`)

```ruby
params do
  optional :metadata, type: Hash, documentation: {
    min_properties: 2,
    max_properties: 10
  }
end
# => { minProperties: 2, maxProperties: 10 }
```

### 7. externalDocs (`parse_params.rb`)

Supports full object and URL-only shorthand:

```ruby
# Full object
params do
  optional :query, type: String, documentation: {
    external_docs: {
      url: 'https://docs.example.com/search-syntax',
      description: 'Search query syntax documentation'
    }
  }
end

# URL-only shorthand
params do
  optional :format, type: String, documentation: {
    external_docs: 'https://docs.example.com/formats'
  }
end
```

### 8. Content Field (`parse_params.rb`)

Alternative to schema for complex parameter serialization (e.g., JSON in query strings):

```ruby
params do
  optional :filter, type: String, documentation: {
    content: {
      'application/json' => {
        schema: {
          type: 'object',
          properties: {
            field: { type: 'string' },
            operator: { type: 'string' }
          }
        }
      }
    }
  }
end
```

### 9. Property Keys in MoveParams (`move_params.rb`)

Added `readOnly`, `writeOnly`, `title`, `not`, `minProperties`, `maxProperties`, and `externalDocs` to `property_keys` so these are preserved when parameters are moved into request body definitions.

## Files Modified

- `lib/grape-swagger/doc_methods/parse_params.rb` - All new documentation key handlers
- `lib/grape-swagger/doc_methods/move_params.rb` - Extended property_keys
- `spec/grape-swagger/openapi/reference_overrides_spec.rb` - New spec (6 examples)
- `spec/grape-swagger/openapi/schema_title_not_spec.rb` - New spec (9 examples)
- `spec/grape-swagger/openapi/object_constraints_spec.rb` - New spec (8 examples)
- `spec/grape-swagger/openapi/schema_external_docs_spec.rb` - New spec (6 examples)
- `spec/grape-swagger/openapi/parameter_content_spec.rb` - New spec (5 examples)

## Test Count

1347 examples, 0 failures (34 new tests added)
