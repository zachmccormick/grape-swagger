# Sprint 9: Nullable & Binary Handling
## Phase 3 - Schema Alignment

### Sprint Overview
**Duration**: 3 days
**Sprint Goal**: Implement proper nullable types using type arrays and binary data encoding per JSON Schema 2020-12.

### User Stories

#### Story 9.1: Nullable Type Migration
**As a** spec consumer
**I want** nullable types expressed as type arrays
**So that** schemas comply with JSON Schema 2020-12

**Acceptance Criteria**:
- [ ] `nullable: true` converted to type array for OpenAPI 3.1.0
- [ ] `{type: 'string', nullable: true}` becomes `{type: ['string', 'null']}`
- [ ] Non-nullable types remain single type
- [ ] Swagger 2.0 preserves `nullable: true` format
- [ ] Multiple nullable fields handled correctly
- [ ] Nullable arrays: `{type: ['array', 'null'], items: {...}}`

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Nullable string becomes type array ['string', 'null']
- Nullable integer becomes type array ['integer', 'null']
- Non-nullable string stays single type 'string'
- Nullable array preserves items schema
- Nullable object preserves properties
- Swagger 2.0 keeps nullable: true unchanged
- Type array deduplication (no duplicate 'null')
- Nullable with enum preserves enum values
```

#### Story 9.2: Binary Data Encoding
**As an** API provider
**I want** binary data properly encoded
**So that** file uploads are documented correctly

**Acceptance Criteria**:
- [ ] Binary type uses `contentEncoding: 'base64'`
- [ ] `contentMediaType` specifies the media type
- [ ] Byte type uses `contentEncoding: 'base64'`
- [ ] File upload parameters properly documented
- [ ] Multiple binary fields supported

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Binary type has contentEncoding: 'base64'
- Binary type has contentMediaType: 'application/octet-stream'
- Byte type has contentEncoding: 'base64'
- File parameter uses binary schema
- Image upload with specific contentMediaType
- Multiple file uploads documented
- Swagger 2.0 keeps format: 'binary'
```

#### Story 9.3: File Upload Handling
**As a** developer
**I want** file uploads properly documented
**So that** clients know how to upload files

**Acceptance Criteria**:
- [ ] File parameters converted to binary schema
- [ ] Multipart requests use proper encoding
- [ ] Multiple files in single request
- [ ] File with metadata (filename, content-type)
- [ ] Required vs optional file uploads

**TDD Tests Required**:
```ruby
# RED Phase tests:
- File parameter in multipart request
- Multiple file upload schema
- File with filename metadata
- Required file parameter
- Optional file parameter
- File array (multiple files same field)
- Mixed file and data in multipart
```

### Technical Tasks

#### Task 9.1: NullableTypeHandler
- [ ] Create `nullable_type_handler.rb`
- [ ] Transform nullable: true to type array
- [ ] Preserve non-schema fields
- [ ] Handle edge cases (already type array)

**Implementation Structure**:
```ruby
module GrapeSwagger
  module OpenAPI
    class NullableTypeHandler
      def self.transform(schema, version)
        return schema unless version.openapi_3_1_0?
        return schema unless schema[:nullable]

        result = schema.dup
        result.delete(:nullable)

        current_type = result[:type]
        result[:type] = normalize_type_array(current_type)
        result
      end

      private

      def self.normalize_type_array(type)
        types = Array(type)
        types << 'null' unless types.include?('null')
        types.uniq
      end
    end
  end
end
```

#### Task 9.2: BinaryDataEncoder
- [ ] Create `binary_data_encoder.rb`
- [ ] Handle binary/byte types
- [ ] Add contentEncoding and contentMediaType
- [ ] Support custom media types

**Implementation Structure**:
```ruby
module GrapeSwagger
  module OpenAPI
    class BinaryDataEncoder
      BINARY_ENCODINGS = {
        'binary' => {
          contentEncoding: 'base64',
          contentMediaType: 'application/octet-stream'
        },
        'byte' => {
          contentEncoding: 'base64'
        }
      }.freeze

      def self.encode(schema, version)
        return schema unless version.openapi_3_1_0?

        format = schema[:format]
        return schema unless BINARY_ENCODINGS.key?(format)

        result = schema.dup
        result.delete(:format)
        result.merge(BINARY_ENCODINGS[format])
      end
    end
  end
end
```

#### Task 9.3: Integration
- [ ] Integrate NullableTypeHandler into schema generation
- [ ] Integrate BinaryDataEncoder into type mapping
- [ ] Update endpoint.rb for file uploads
- [ ] Update RequestBodyBuilder for multipart files

### Definition of Done
- [ ] All RED tests written first
- [ ] All tests GREEN
- [ ] Code refactored
- [ ] Nullable types properly handled
- [ ] Binary data properly encoded
- [ ] File uploads documented correctly
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 8
- **Estimated Hours**: 24
- **Risk Level**: Medium
- **Dependencies**: Sprint 8 complete

### Nullable Transformation Examples

**String Field**:
```yaml
# Swagger 2.0
type: string
nullable: true

# OpenAPI 3.1.0
type:
  - string
  - "null"
```

**Object Field**:
```yaml
# Swagger 2.0
type: object
nullable: true
properties:
  name:
    type: string

# OpenAPI 3.1.0
type:
  - object
  - "null"
properties:
  name:
    type: string
```

**Array Field**:
```yaml
# Swagger 2.0
type: array
nullable: true
items:
  type: string

# OpenAPI 3.1.0
type:
  - array
  - "null"
items:
  type: string
```

### Binary Data Examples

**File Upload**:
```yaml
# Swagger 2.0
type: string
format: binary

# OpenAPI 3.1.0
type: string
contentEncoding: base64
contentMediaType: application/octet-stream
```

**Image Upload**:
```yaml
# OpenAPI 3.1.0
type: string
contentEncoding: base64
contentMediaType: image/png
```

---

**Next Sprint**: Sprint 10 will implement advanced JSON Schema 2020-12 validation features.
