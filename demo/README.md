# Grape-Swagger OpenAPI 3.1.0 Demo

This Rails application demonstrates the new OpenAPI 3.1.0 features supported by grape-swagger.

## Features Demonstrated

### OpenAPI 3.1.0 Specific Features

1. **SPDX License Identifier** - The `info.license.identifier` field uses SPDX identifiers
2. **Info Summary** - The `info.summary` field for brief API description
3. **OpenID Connect Security** - `type: openIdConnect` with `openIdConnectUrl`
4. **Mutual TLS Security** - `type: mutualTLS` for client certificate auth
5. **OAuth2 with Multiple Flows** - Authorization code, client credentials, refresh URLs
6. **Server Variables** - Dynamic server URLs with variables
7. **Webhooks** - Async event notifications (configured in API)

### API Resources

- **Pets** - Polymorphic entities (Dog, Cat, Bird) with nullable fields
- **Users** - User management with nullable profile fields
- **Orders** - Order lifecycle with webhooks for status changes
- **Files** - Binary file uploads demonstrating contentEncoding
- **Payments** - oneOf polymorphism (CreditCard, BankAccount, DigitalWallet)

## Setup

```bash
cd demo
bundle install
```

## Running the Server

```bash
bundle exec rails server
```

The API will be available at http://localhost:3000

## Viewing the Swagger Documentation

```bash
# Get the OpenAPI spec
curl http://localhost:3000/swagger_doc

# Pretty print
curl http://localhost:3000/swagger_doc | python3 -m json.tool
```

## Key Configuration

See `app/api/api/root.rb` for the complete swagger configuration:

```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',

  # SPDX License (OpenAPI 3.1.0)
  info: {
    license: {
      name: 'MIT',
      identifier: 'MIT'
    },
    summary: 'Brief API summary'
  },

  # Enhanced Security Schemes
  security_definitions: {
    openid_connect: {
      type: 'openIdConnect',
      openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
    },
    mutual_tls: {
      type: 'mutualTLS',
      description: 'Client certificate required'
    },
    oauth2: {
      type: 'oauth2',
      flows: {
        authorizationCode: {
          authorization_url: 'https://auth.example.com/authorize',
          token_url: 'https://auth.example.com/token',
          refresh_url: 'https://auth.example.com/refresh',
          scopes: { ... }
        }
      }
    }
  },

  # Server Variables
  servers: [
    {
      url: 'https://api.example.com/{version}',
      variables: {
        version: { default: 'v1', enum: ['v1', 'v2'] }
      }
    }
  ],

  # Webhooks
  webhooks: {
    orderCreated: {
      method: :post,
      summary: 'Order created notification',
      request: { schema: { '$ref' => '#/components/schemas/Order' } }
    }
  }
)
```

## Entity Examples

### Polymorphic Entities (Pet)

```ruby
# Base entity
class Pet < Grape::Entity
  expose :pet_type, documentation: {
    type: String,
    values: %w[dog cat bird]
  }
end

# Extended entities
class Dog < Pet
  expose :breed
  expose :is_trained
end

class Cat < Pet
  expose :color
  expose :hunting_skill
end
```

### Nullable Fields

```ruby
expose :bio, documentation: {
  type: String,
  nullable: true  # Converts to type: ['string', 'null'] in OpenAPI 3.1.0
}
```

### Binary Data

```ruby
expose :content, documentation: {
  type: String,
  format: 'binary'  # Uses contentEncoding in OpenAPI 3.1.0
}
```

## Project Structure

```
demo/
├── app/
│   └── api/
│       ├── api/
│       │   └── root.rb          # Main API with swagger config
│       └── v1/
│           ├── entities/        # Grape entities
│           │   ├── pet.rb       # Pet, Dog, Cat, Bird
│           │   ├── user.rb      # User, UserCompact
│           │   ├── order.rb     # Order, OrderItem
│           │   ├── file_upload.rb
│           │   └── payment.rb   # PaymentMethod, CreditCard, etc.
│           ├── pets_api.rb
│           ├── users_api.rb
│           ├── orders_api.rb
│           ├── files_api.rb
│           └── payments_api.rb
├── config/
│   ├── application.rb
│   ├── routes.rb
│   └── initializers/
│       └── grape.rb
├── Gemfile
└── README.md
```

## Dependencies

- Rails 7.1+
- Grape 2.0+
- grape-entity 1.0+
- grape-swagger (local with OpenAPI 3.1.0 support)
- grape-swagger-entity 0.5+
