# OpenAPI 3.1.0 Validation Bugs

This document tracks bugs discovered when validating the OpenAPI 3.1.0 output from grape-swagger using the [IBM OpenAPI Validator](https://github.com/IBM/openapi-validator).

## Critical Bugs (Spec Invalid)

### BUG-001: `produces` Property in Operations (Swagger 2.0 Remnant)

**Severity**: Critical
**Affected**: All operations (GET, POST, PUT, DELETE, PATCH)

**Problem**: The `produces` property is being output in operations, but this is a Swagger 2.0 property. In OpenAPI 3.x, content types are specified in the `responses.content` object.

**Validator Error**:
```
"get" property must not have unevaluated properties.
```

**Current Output**:
```json
{
  "get": {
    "produces": ["application/json"],  // WRONG - Swagger 2.0
    "responses": { ... }
  }
}
```

**Expected Output**:
```json
{
  "get": {
    "responses": {
      "200": {
        "content": {
          "application/json": { ... }
        }
      }
    }
  }
}
```

**Fix Location**: `lib/grape-swagger/doc_methods/produces.rb` or wherever `produces` is added to operations.

---

### BUG-002: `consumes` Property in Operations (Swagger 2.0 Remnant)

**Severity**: Critical
**Affected**: POST, PUT, PATCH operations

**Problem**: The `consumes` property is being output in operations, but this is a Swagger 2.0 property. In OpenAPI 3.x, content types are specified in `requestBody.content`.

**Current Output**:
```json
{
  "post": {
    "consumes": ["application/json"],  // WRONG - Swagger 2.0
    "requestBody": { ... }
  }
}
```

**Expected Output**:
```json
{
  "post": {
    "requestBody": {
      "content": {
        "application/json": { ... }
      }
    }
  }
}
```

**Fix Location**: `lib/grape-swagger/doc_methods/consumes.rb` or operation building code.

---

### BUG-003: Schema References Point to Non-Existent Paths

**Severity**: Critical
**Affected**: All `$ref` to entity schemas

**Problem**: Schema references use `#/components/schemas/X` but schemas are being placed in `definitions/` (Swagger 2.0 location).

**Validator Error**:
```
'#/components/schemas/V1_Entities_Pet' does not exist
```

**Current Output**:
```json
{
  "paths": {
    "/pets": {
      "get": {
        "responses": {
          "200": {
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/V1_Entities_Pet"  // Points here
                }
              }
            }
          }
        }
      }
    }
  },
  "definitions": {  // But schemas are here!
    "V1_Entities_Pet": { ... }
  }
}
```

**Expected Output**:
```json
{
  "components": {
    "schemas": {
      "V1_Entities_Pet": { ... }
    }
  }
}
```

**Fix Location**: Schema placement logic - should use `components.schemas` for OpenAPI 3.x instead of `definitions`.

---

### BUG-004: `$ref` Placed Next to Other Properties

**Severity**: Critical
**Affected**: Entity schemas with additional properties

**Problem**: In OpenAPI 3.1.0 (which uses JSON Schema 2020-12), `$ref` cannot be placed next to other properties. This was allowed in earlier versions.

**Validator Error**:
```
$ref must not be placed next to any other properties
```

**Current Output**:
```json
{
  "V1_Entities_Order": {
    "properties": {
      "customer": {
        "$ref": "#/definitions/V1_Entities_UserCompact",
        "description": "Customer info"  // NOT ALLOWED next to $ref
      }
    }
  }
}
```

**Expected Output**:
```json
{
  "V1_Entities_Order": {
    "properties": {
      "customer": {
        "allOf": [
          { "$ref": "#/components/schemas/V1_Entities_UserCompact" }
        ],
        "description": "Customer info"
      }
    }
  }
}
```

**Fix Location**: Entity/schema building when adding descriptions or other metadata to `$ref` properties.

---

### BUG-005: Invalid `in` Property Values for Parameters

**Severity**: Critical
**Affected**: File upload parameters

**Problem**: The `in` property for some parameters has invalid values.

**Validator Error**:
```
"in" property must be equal to one of the allowed values
```

**Valid Values**: `query`, `header`, `path`, `cookie` (OpenAPI 3.x) or `formData` (Swagger 2.0 only)

**Fix Location**: Parameter building for file uploads - `formData` is not valid in OpenAPI 3.x.

---

### BUG-006: Invalid Type Values

**Severity**: Critical
**Affected**: File type parameters

**Problem**: The `type` property has invalid values like `file` which is not a valid JSON Schema type.

**Validator Error**:
```
Invalid type; valid types are
"type" property must be equal to one of the allowed values
```

**Valid Types**: `string`, `number`, `integer`, `boolean`, `array`, `object`, `null` (3.1.0 only)

**Current Output**:
```json
{
  "type": "file"  // INVALID
}
```

**Expected Output** (for file uploads in OpenAPI 3.x):
```json
{
  "type": "string",
  "format": "binary"
}
```

**Fix Location**: Type mapping for file parameters.

---

## High Priority Bugs (Spec Incomplete)

### BUG-007: Servers Array Not Output

**Severity**: High
**Affected**: Root spec

**Problem**: The `servers` configuration is provided but not appearing in the output.

**Validator Warning**:
```
OpenAPI "servers" must be present and non-empty array.
```

**Configuration**:
```ruby
servers: [
  { url: 'https://api.example.com/v1', description: 'Production' }
]
```

**Fix Location**: Root spec building - servers array not being included.

---

### BUG-008: Webhooks Not Output

**Severity**: High
**Affected**: Root spec

**Problem**: Webhooks are configured but not appearing in the output.

**Configuration**:
```ruby
webhooks: {
  orderCreated: {
    method: :post,
    summary: 'Order created',
    ...
  }
}
```

**Expected Output**:
```json
{
  "webhooks": {
    "orderCreated": {
      "post": { ... }
    }
  }
}
```

**Fix Location**: `WebhookBuilder` integration with main spec generation.

---

### BUG-009: Schemas Using Legacy `definitions` Instead of `components/schemas`

**Severity**: High
**Affected**: All entity schemas

**Problem**: Schemas are placed in `definitions/` (Swagger 2.0) instead of `components/schemas/` (OpenAPI 3.x).

**Validator Warning**:
```
$refs to schemas should start with '#/components/schemas/'
```

**Fix Location**: Schema placement in spec building.

---

## Medium Priority Bugs (Spec Suboptimal)

### BUG-010: mutualTLS Security Scheme Type May Be Invalid

**Severity**: Medium
**Affected**: Security schemes

**Problem**: The validator reports an issue with security scheme type.

**Validator Error**:
```
Security scheme property 'type' must be one of
```

**Note**: `mutualTLS` is valid in OpenAPI 3.1.0 but the exact format needs verification.

**Fix Location**: `SecuritySchemeBuilder` - verify mutualTLS output format.

---

### BUG-011: Request Body Schemas Empty

**Severity**: Medium
**Affected**: POST/PUT operations

**Problem**: Request body schemas have empty `properties` objects.

**Validator Warning**:
```
Request and response bodies must be models - their schemas must define `properties`
```

**Current Output**:
```json
{
  "requestBody": {
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "properties": {}  // Empty!
        }
      }
    }
  }
}
```

**Fix Location**: Request body building - parameters not being included in schema.

---

## Tracking

| Bug ID | Status | Priority | Assignee |
|--------|--------|----------|----------|
| BUG-001 | Open | Critical | - |
| BUG-002 | Open | Critical | - |
| BUG-003 | Open | Critical | - |
| BUG-004 | Open | Critical | - |
| BUG-005 | Open | Critical | - |
| BUG-006 | Open | Critical | - |
| BUG-007 | Open | High | - |
| BUG-008 | Open | High | - |
| BUG-009 | Open | High | - |
| BUG-010 | Open | Medium | - |
| BUG-011 | Open | Medium | - |

## Notes

### Excluded from Bug List

The following validator findings are **not bugs** but IBM style preferences:

- "Integer schemas should define property 'minimum'/'maximum'" - Style preference
- "Operations should not return an array as the top-level structure" - Style preference
- "Operations must have a non-empty summary" - Style preference
- "Response bodies should include an example response" - Style preference
- "Schemas should have a non-empty description" - Style preference
- "Operation ids must be snake case" - Style preference
- "A security scheme is defined but never used" - Intentional (demo shows available schemes)

### Root Cause Analysis

Many of these bugs stem from grape-swagger's OpenAPI 3.x support being incomplete:

1. **Swagger 2.0 artifacts** (BUG-001, 002, 005, 006, 009) - The codebase still outputs Swagger 2.0 properties even when OpenAPI 3.x is selected.

2. **Schema location** (BUG-003, 009) - Schemas go to `definitions` instead of `components/schemas`.

3. **New features not integrated** (BUG-007, 008) - New builders exist but aren't connected to the main spec generation.

4. **JSON Schema 2020-12 compliance** (BUG-004) - OpenAPI 3.1.0 uses JSON Schema 2020-12 which has stricter `$ref` rules.
