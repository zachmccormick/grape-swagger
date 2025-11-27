# Encoding Object

A single encoding definition applied to a single schema property.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `contentType` | string | No | ✅ | Property content type for specific encoding |
| `headers` | Map[string, Header Object \| Reference Object] | No | ✅ | Additional headers (multipart only, Content-Type ignored) |
| `style` | string | No | ✅ | RFC6570-style serialization (form media types only) |
| `explode` | boolean | No | ✅ | Separate parameters per array/object value |
| `allowReserved` | boolean | No | ✅ | Allow RFC6570 reserved expansion (form-data only) |

## Status

✅ **Fully Implemented**

The Encoding Object is fully supported for multipart and application/x-www-form-urlencoded request bodies. All five fields from the OpenAPI 3.1.0 specification are implemented.

## Applicability Notes

Per the OpenAPI 3.1.0 specification:

- **`contentType`**: Works with all media types. Specifies the Content-Type for encoding a specific property. Can accept comma-separated list of media types.
- **`headers`**: Only applies to `multipart` request body media types. The `Content-Type` header should be described using `contentType` instead.
- **`style`**, **`explode`**, **`allowReserved`**: Ignored for non-form media types. When explicitly defined, these override the `contentType` field.
- **`allowReserved`**: Only applies to `application/x-www-form-urlencoded` or `multipart/form-data` media types.

## Use Case

The Encoding Object is primarily used when you need to specify how individual properties in a multipart request body should be encoded:

```json
{
  "requestBody": {
    "content": {
      "multipart/form-data": {
        "schema": {
          "type": "object",
          "properties": {
            "file": {
              "type": "string",
              "format": "binary"
            },
            "metadata": {
              "type": "object"
            }
          }
        },
        "encoding": {
          "file": {
            "contentType": "application/octet-stream"
          },
          "metadata": {
            "contentType": "application/json"
          }
        }
      }
    }
  }
}
```

## TODO

- [ ] Implement encoding support for multipart forms
