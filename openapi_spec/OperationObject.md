# Operation Object

Describes a single API operation on a path.

## Fields

| Field | Type | Required | Supported | Notes |
|-------|------|----------|-----------|-------|
| `tags` | [string] | No | :white_check_mark: | Set via `tags:` in desc |
| `summary` | string | No | :white_check_mark: | Set via `summary:` in desc |
| `description` | string | No | :white_check_mark: | Set via `detail:` in desc |
| `externalDocs` | [External Documentation Object](ExternalDocumentationObject.md) | No | :white_check_mark: | Set via `external_docs:` in desc |
| `operationId` | string | No | :white_check_mark: | Auto-generated or set via `nickname:` |
| `parameters` | [[Parameter Object](ParameterObject.md) \| Reference Object] | No | :white_check_mark: | From Grape params |
| `requestBody` | [Request Body Object](RequestBodyObject.md) \| Reference Object | No | :white_check_mark: | For POST/PUT/PATCH (3.1.0) |
| `responses` | [Responses Object](ResponsesObject.md) | Yes | :white_check_mark: | From `success:`/`failure:` |
| `callbacks` | Map[string, [Callback Object](CallbackObject.md) \| Reference Object] | No | :white_check_mark: | Set via `callbacks:` in desc |
| `deprecated` | boolean | No | :white_check_mark: | Set via `deprecated: true` |
| `security` | [[Security Requirement Object](SecurityRequirementObject.md)] | No | :white_check_mark: | Set via `security:` in desc |
| `servers` | [[Server Object](ServerObject.md)] | No | :x: | Operation-level servers |

## Usage

```ruby
desc 'Get a specific user',
     summary: 'Retrieve user by ID',
     detail: 'Returns detailed information about a user including profile data.',
     tags: ['users'],
     deprecated: true,
     security: [{ api_key: [] }],
     external_docs: {
       description: 'User API documentation',
       url: 'https://example.com/docs/users'
     },
     success: {
       model: Entities::User,
       examples: { 'application/json' => { id: 1, name: 'John' } }
     },
     failure: [
       { code: 404, message: 'User not found' },
       { code: 401, message: 'Unauthorized' }
     ]
params do
  requires :id, type: Integer, desc: 'User ID'
end
get ':id' do
  # ...
end
```

## Output Example

```json
{
  "get": {
    "tags": ["users"],
    "summary": "Retrieve user by ID",
    "description": "Returns detailed information about a user including profile data.",
    "externalDocs": {
      "description": "User API documentation",
      "url": "https://example.com/docs/users"
    },
    "operationId": "getUsersId",
    "deprecated": true,
    "security": [{ "api_key": [] }],
    "parameters": [
      {
        "name": "id",
        "in": "path",
        "description": "User ID",
        "required": true,
        "schema": { "type": "integer" }
      }
    ],
    "responses": {
      "200": {
        "description": "Retrieve user by ID",
        "content": {
          "application/json": {
            "schema": { "$ref": "#/components/schemas/User" },
            "example": { "id": 1, "name": "John" }
          }
        }
      },
      "404": {
        "description": "User not found"
      },
      "401": {
        "description": "Unauthorized"
      }
    }
  }
}
```

## Desc Options Mapping

| Grape desc option | OpenAPI field |
|-------------------|---------------|
| First argument (string) | `description` |
| `summary:` | `summary` |
| `detail:` | `description` (overrides first arg) |
| `tags:` | `tags` |
| `deprecated:` | `deprecated` |
| `nickname:` | `operationId` |
| `security:` | `security` |
| `external_docs:` | `externalDocs` |
| `success:` | `responses.200` |
| `failure:` | `responses.{code}` |
| `consumes:` | `requestBody.content` keys (3.1.0) |
| `produces:` | `responses.*.content` keys (3.1.0) |

## Tests

- `spec/swagger_v2/api_swagger_v2_detail_spec.rb`
- `spec/swagger_v2/deprecated_field_spec.rb`
- `spec/openapi_v3_1/style_features_spec.rb`
- `spec/grape-swagger/openapi/advanced_features_spec.rb` (externalDocs)

## Implementation

- `lib/grape-swagger/endpoint.rb`

## TODO

- [ ] Add operation-level `servers` support
