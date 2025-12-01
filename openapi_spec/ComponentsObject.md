# Components Object

Holds a set of reusable objects for different aspects of the OAS. All objects defined within the components object will have no effect on the API unless they are explicitly referenced from properties outside the components object.

## Fields

| Field | Type | Required | Auto-Generated | Notes |
|-------|------|----------|----------------|-------|
| `schemas` | Map[string, Schema Object \| Reference Object] | No | :white_check_mark: | Reusable schemas (auto-generated from entities) |
| `responses` | Map[string, Response Object \| Reference Object] | No | :x: | Reusable responses (manual only) |
| `parameters` | Map[string, Parameter Object \| Reference Object] | No | :x: | Reusable parameters (manual only) |
| `examples` | Map[string, Example Object \| Reference Object] | No | :x: | Reusable examples (manual only) |
| `requestBodies` | Map[string, Request Body Object \| Reference Object] | No | :x: | Reusable request bodies (manual only) |
| `headers` | Map[string, Header Object \| Reference Object] | No | :x: | Reusable headers (manual only) |
| `securitySchemes` | Map[string, Security Scheme Object \| Reference Object] | No | :white_check_mark: | Security definitions (auto-generated) |
| `links` | Map[string, Link Object \| Reference Object] | No | :x: | Reusable links (manual only) |
| `callbacks` | Map[string, Callback Object \| Reference Object] | No | :x: | Reusable callbacks (manual only) |
| `pathItems` | Map[string, Path Item Object \| Reference Object] | No | :x: | Reusable path items (3.1.0, manual only) |

## Component Key Naming Constraints

All component keys (map keys) must match the regular expression pattern: `^[a-zA-Z0-9\.\-_]+$`

**Valid examples:**
- `User`
- `User_1`
- `User_Name`
- `user-name`
- `my.org.User`

**Invalid examples:**
- `User@Email` (contains @)
- `User/Type` (contains /)
- `User Name` (contains space)

## Auto-Generation vs Manual Support

**Auto-Generated (✅):**
- `schemas`: Automatically created from `Grape::Entity` definitions and inline schemas
- `securitySchemes`: Automatically created from `security_definitions` configuration
- `parameters`: Automatically created from `ReusableParameter` subclasses (see [ReusableComponents.md](ReusableComponents.md))
- `responses`: Automatically created from `ReusableResponse` subclasses (see [ReusableComponents.md](ReusableComponents.md))
- `headers`: Automatically created from `ReusableHeader` subclasses (see [ReusableComponents.md](ReusableComponents.md))

**Manual Only (❌):**
- `examples`, `requestBodies`, `links`, `callbacks`, `pathItems` must be manually added to the OpenAPI document
- grape-swagger does not automatically extract and deduplicate these from endpoint definitions
- You can add them by modifying the generated OpenAPI document or extending grape-swagger

**Note:** While grape-swagger can accept and pass through manually-added components, it does not automatically generate or reference them. The "Auto-Generated" column indicates whether grape-swagger will populate these components automatically from your API definitions.

### Reusable Components DSL

grape-swagger provides a DSL for defining reusable parameters, responses, and headers using Ruby classes that auto-register on load. These classes follow a similar pattern to `Grape::Entity` and use Ruby's `inherited` hook to automatically register themselves in the components registry.

See [ReusableComponents.md](ReusableComponents.md) for complete documentation and examples.

## Usage

### Schemas (via Grape::Entity)

```ruby
class UserEntity < Grape::Entity
  expose :id, documentation: { type: Integer, desc: 'User ID' }
  expose :name, documentation: { type: String, desc: 'Full name' }
  expose :email, documentation: { type: String, format: 'email' }
end

class API < Grape::API
  desc 'Get user',
       success: UserEntity
  get '/users/:id' do
    # Automatically adds UserEntity to components/schemas
  end
end
```

### Security Schemes

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  security_definitions: {
    api_key: {
      type: 'apiKey',
      name: 'X-API-Key',
      in: 'header'
    },
    bearer_auth: {
      type: 'http',
      scheme: 'bearer',
      bearerFormat: 'JWT'
    }
  }
)
```

## Output Example

```json
{
  "components": {
    "schemas": {
      "User": {
        "type": "object",
        "properties": {
          "id": {
            "type": "integer",
            "format": "int32",
            "description": "User ID"
          },
          "name": {
            "type": "string",
            "description": "Full name"
          },
          "email": {
            "type": "string",
            "format": "email"
          }
        },
        "required": ["id", "name", "email"]
      }
    },
    "securitySchemes": {
      "api_key": {
        "type": "apiKey",
        "name": "X-API-Key",
        "in": "header"
      },
      "bearer_auth": {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "JWT"
      }
    }
  }
}
```

## Tests

- `spec/swagger_v2/api_swagger_v2_mounted_spec.rb`
- `spec/grape-swagger/openapi/security_scheme_builder_spec.rb`
- `spec/lib/move_params_spec.rb`

## Implementation

- `lib/grape-swagger/endpoint.rb` (schema generation)
- `lib/grape-swagger/openapi/security_scheme_builder.rb`
- `lib/grape-swagger/doc_methods/move_params.rb`

## TODO

- [x] Add reusable responses support (via ReusableResponse DSL)
- [x] Add reusable parameters support (via ReusableParameter DSL)
- [x] Add reusable headers support (via ReusableHeader DSL)
- [ ] Add reusable examples support
- [ ] Add reusable request bodies support
- [ ] Add reusable links support
- [ ] Add reusable callbacks support
- [ ] Add reusable pathItems support (3.1.0)
