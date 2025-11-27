# XML Object - OpenAPI 3.1.0 Specification

**Status:** Not Implemented in grape-swagger

**Specification Reference:** OpenAPI 3.1.0 Section 4.8.26

---

## Overview

The XML Object provides metadata for representing schema properties in XML format. It allows control over element naming, attributes, namespaces, and array serialization when APIs produce or consume XML content.

This object is used within Schema Objects to customize how JSON Schema properties are represented in XML.

---

## Fixed Fields

| Field Name | Type | Required | Supported | Description |
|------------|------|----------|-----------|-------------|
| `name` | `string` | No | :x: | Replaces the name of an element. When dealing with the `schema` object properties, the `name` applies to the elements themselves, not the schema. |
| `namespace` | `string` | No | :x: | The URI of the namespace definition. This URI MUST be in the form of a URL. |
| `prefix` | `string` | No | :x: | The prefix to be used for the name. |
| `attribute` | `boolean` | No | :x: | Declares whether the property should be serialized as an XML attribute rather than an element. Defaults to `false`. |
| `wrapped` | `boolean` | No | :x: | Signifies whether an array is wrapped in a containing element. When `true`, an outer element wraps the array. Applies only to arrays. Defaults to `false`. |

---

## Extension Support

This object MAY be extended with [Specification Extensions](https://spec.openapis.org/oas/v3.1.0#specification-extensions) (fields starting with `x-`).

---

## Usage Examples

### Example 1: Basic Element Name Override

**Schema:**
```yaml
type: object
properties:
  person:
    type: object
    xml:
      name: user
```

**XML Representation:**
```xml
<user>
  <!-- person properties -->
</user>
```

### Example 2: XML Attribute

**Schema:**
```yaml
type: object
properties:
  id:
    type: integer
    xml:
      attribute: true
  name:
    type: string
```

**XML Representation:**
```xml
<item id="123">
  <name>John</name>
</item>
```

### Example 3: Wrapped Array

**Schema:**
```yaml
type: object
properties:
  items:
    type: array
    items:
      type: string
    xml:
      wrapped: true
```

**XML Representation (wrapped=true):**
```xml
<items>
  <items>item1</items>
  <items>item2</items>
</items>
```

**XML Representation (wrapped=false, default):**
```xml
<items>item1</items>
<items>item2</items>
```

### Example 4: Namespace and Prefix

**Schema:**
```yaml
type: object
properties:
  data:
    type: string
    xml:
      namespace: "http://example.com/schema"
      prefix: "ex"
```

**XML Representation:**
```xml
<ex:data xmlns:ex="http://example.com/schema">value</ex:data>
```

### Example 5: Complex Example (From Spec)

**Schema:**
```yaml
type: object
properties:
  id:
    type: integer
    format: int32
    xml:
      attribute: true
  name:
    type: string
    xml:
      namespace: "http://example.com/schema"
      prefix: "sample"
```

**XML Representation:**
```xml
<Person id="123">
  <sample:name xmlns:sample="http://example.com/schema">John</sample:name>
</Person>
```

---

## Implementation Notes

### Why XML Object is Not Implemented

1. **Grape Framework Focus:** Grape primarily focuses on JSON APIs, with limited XML support
2. **Low Demand:** Modern API development heavily favors JSON over XML
3. **Complexity vs. Usage:** The XML Object adds significant complexity for a rarely-used feature
4. **Entity Serialization:** grape-entity (used with grape-swagger) doesn't have built-in XML metadata

### When You Might Need This

The XML Object is useful when:

- Your API produces or consumes XML content types
- You need fine-grained control over XML serialization
- You're documenting legacy APIs that use XML
- You need to support XML namespaces
- You want arrays to serialize differently in XML vs JSON

### Workarounds

If you need to document XML representations:

1. **Use Description Field:** Document XML structure in the schema `description`
2. **External Documentation:** Link to separate XML documentation using `externalDocs`
3. **Examples:** Provide XML examples in the `examples` field using `text/xml` media type
4. **Manual Specification Extensions:** Add custom `x-xml-*` fields if needed

---

## Specification Alignment

### Coverage Status

- **Total Fields:** 5
- **Implemented:** 0 (0%)
- **Not Implemented:** 5 (100%)

### Fields Not Implemented

All fields are currently not implemented:
- :x: `name` - Element name override
- :x: `namespace` - XML namespace URI
- :x: `prefix` - Namespace prefix
- :x: `attribute` - Serialize as XML attribute
- :x: `wrapped` - Wrap arrays in container element

---

## Related Objects

- **Schema Object:** The XML Object is used within Schema Objects via the `xml` field
- **Media Type Object:** Specifies when `application/xml` or `text/xml` content types are used
- **Response Object:** Can contain XML content in response bodies
- **Request Body Object:** Can accept XML content in request bodies

---

## References

- [OpenAPI 3.1.0 Specification - XML Object](https://spec.openapis.org/oas/v3.1.0#xml-object)
- [OpenAPI 3.0.x Specification - XML Object](https://spec.openapis.org/oas/v3.0.3#xml-object) (Same definition)
- [W3C XML Namespaces](https://www.w3.org/TR/xml-names/)

---

**Last Updated:** 2025-11-26
**OpenAPI Version:** 3.1.0
**Implementation Status:** Not Implemented (0% coverage)
