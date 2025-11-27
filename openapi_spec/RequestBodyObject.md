# Request Body Object

Describes a single request body.

**Note:** This is an OpenAPI 3.x object. In Swagger 2.0, body content was described using `in: body` parameters.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `description` | string | No | :white_check_mark: | From first body param description. Supports CommonMark syntax for formatted text. |
| `content` | Map[string, [Media Type Object](MediaTypeObject.md)] | Yes | :white_check_mark: | Content by media type. More specific media types (e.g., `text/plain`) override generic ones (e.g., `text/*`). |
| `required` | boolean | No | :white_check_mark: | True if any body param is required. Defaults to `false` when not specified. |

## Usage

```ruby
desc 'Create a user',
     consumes: ['application/json', 'application/xml']
params do
  requires :name, type: String, desc: 'User name'
  requires :email, type: String, desc: 'User email'
  optional :age, type: Integer, desc: 'User age'
end
post '/users' do
  # ...
end
```

## Output Example

```json
{
  "post": {
    "requestBody": {
      "required": true,
      "content": {
        "application/json": {
          "schema": {
            "$ref": "#/components/schemas/postUsers"
          }
        },
        "application/xml": {
          "schema": {
            "$ref": "#/components/schemas/postUsers"
          }
        }
      }
    }
  }
}
```

## With Entity Reference

```ruby
desc 'Create a user' do
  success model: Entities::User
end
params do
  requires :user, type: Hash, documentation: { param_type: 'body' } do
    requires :name, type: String
    requires :email, type: String
  end
end
post '/users' do
  # ...
end
```

## Multiple Content Types

The `consumes:` option in desc determines which content types appear in the requestBody:

```ruby
desc 'Upload data',
     consumes: ['application/json', 'multipart/form-data']
```

For file uploads, use `multipart/form-data`:

```ruby
desc 'Upload file',
     consumes: ['multipart/form-data']
params do
  requires :file, type: File, desc: 'File to upload'
  optional :description, type: String
end
post '/upload' do
  # ...
end
```

## Tests

- `spec/openapi_3_1_request_body_integration_spec.rb`
- `spec/grape-swagger/openapi/request_body_builder_spec.rb`

## Implementation

- `lib/grape-swagger/openapi/request_body_builder.rb`
- `lib/grape-swagger/endpoint.rb`

## OpenAPI 3.1.0 Notes

- `requestBody` replaces Swagger 2.0's `in: body` and `in: formData` parameters
- File uploads use `type: string, format: binary` instead of `type: file`
- The `consumes` property is removed from operations; content types are in `requestBody.content`
