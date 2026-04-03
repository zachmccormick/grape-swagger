# PR 18: Schema Validation Keys

## Overview

Adds support for additional JSON Schema validation keywords in parameter documentation hashes, expanding grape-swagger's ability to express numeric constraints and array uniqueness in both OpenAPI 3.1.0 and Swagger 2.0 output.

## Changes

### 1. Float and Exclusive Range Detection (`parse_params.rb`)

Previously, only `Integer` ranges generated `minimum`/`maximum` constraints. Now `Numeric` ranges (including `Float`) are supported, and exclusive-end ranges produce `exclusiveMaximum` instead of `maximum`.

```ruby
# Inclusive float range -> minimum + maximum
params do
  optional :rating, type: Float, values: 0.0..5.0
end
# => { minimum: 0.0, maximum: 5.0 }

# Exclusive-end range -> minimum + exclusiveMaximum
params do
  optional :score, type: Float, values: 0.0...1.0
end
# => { minimum: 0.0, exclusiveMaximum: 1.0 }
```

### 2. Numeric Validation Documentation Keys (`parse_params.rb`)

Three new documentation keys for explicit numeric constraints:

```ruby
params do
  optional :rating, type: Float, documentation: {
    exclusive_minimum: 0,
    exclusive_maximum: 5,
    multiple_of: 0.5
  }
end
# => { exclusiveMinimum: 0, exclusiveMaximum: 5, multipleOf: 0.5 }
```

### 3. Unique Items for Arrays (`parse_params.rb`)

```ruby
params do
  optional :tags, type: Array[String], documentation: { unique_items: true }
end
# => { type: 'array', uniqueItems: true, items: { type: 'string' } }
```

### 4. Property Keys in MoveParams (`move_params.rb`)

Added `exclusiveMinimum`, `exclusiveMaximum`, `multipleOf`, `minItems`, `maxItems`, and `uniqueItems` to the `property_keys` list so these validation constraints are preserved when parameters are moved into request body definitions. Array-specific keys (`minItems`, `maxItems`, `uniqueItems`) are also carried through `document_as_array`.

### 5. Request Body Numeric Validation (`request_body_builder.rb`)

The `build_property_schema` method now transfers `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`, and `multipleOf` from parameters into request body schema properties.

## Files Modified

- `lib/grape-swagger/doc_methods/parse_params.rb` - Range detection, numeric validation, unique_items
- `lib/grape-swagger/doc_methods/move_params.rb` - Extended property_keys and array handling
- `lib/grape-swagger/openapi/request_body_builder.rb` - Numeric validation in property schemas
- `spec/swagger_v2/param_values_spec.rb` - Updated float range expectation
- `spec/grape-swagger/openapi/schema_validation_spec.rb` - New spec (6 examples)

## Test Count

1313 examples, 0 failures (6 new tests added)
