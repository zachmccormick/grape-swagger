# PR 17: Extended Reusable Components

## Overview

Extends the reusable components system from PR 16 with three additional component types:

- **ReusableExample**: DSL for defining reusable example components (`summary`, `description`, `value`, `external_value`)
- **ReusableRequestBody**: DSL for defining reusable request body components (`description`, `required`, `json_schema`, `content`)
- **ReusablePathItem**: DSL for defining reusable path item components with operation builders for all HTTP methods
- **Tag name description guard**: Handles `$ref` path items in tag extraction without errors

## ReusableExample

```ruby
class PetDogExample < GrapeSwagger::ReusableExample
  summary 'Example dog'
  description 'A golden retriever named Buddy'
  value({ id: 1, name: 'Buddy', pet_type: 'dog' })
end
```

Supports `external_value` as an alternative to `value` (mutually exclusive per OpenAPI spec):

```ruby
class ExternalPetExample < GrapeSwagger::ReusableExample
  summary 'External pet example'
  external_value 'https://api.example.com/examples/pet.json'
end
```

## ReusableRequestBody

```ruby
class CreatePetBody < GrapeSwagger::ReusableRequestBody
  description 'Payload for creating a new pet'
  required true
  json_schema({ type: 'object', properties: { name: { type: 'string' } } })
end
```

For multiple content types, use the `content` DSL:

```ruby
class MultiFormatBody < GrapeSwagger::ReusableRequestBody
  description 'Multi-format request body'
  content 'application/json', schema: { type: 'object' }
  content 'application/xml', schema: { type: 'object' }
end
```

## ReusablePathItem

```ruby
class UserItemPath < GrapeSwagger::ReusablePathItem
  summary 'User Item Operations'
  description 'Standard CRUD operations for a single user'

  parameter :id, in: :path, type: Integer, required: true, desc: 'User ID'

  get_operation do
    summary 'Get user by ID'
    operation_id 'getUserById'
    tags 'users'
    response 200, description: 'User found'
    response 404, description: 'User not found'
  end

  put_operation do
    summary 'Update user'
    request_body 'application/json', schema: { type: 'object' }
    response 200, description: 'User updated'
  end

  delete_operation do
    summary 'Delete user'
    deprecated true
    response 204, description: 'User deleted'
  end
end
```

Supported operation methods: `get_operation`, `post_operation`, `put_operation`, `patch_operation`, `delete_operation`, `options_operation`, `head_operation`, `trace_operation`.

Path items are referenced from paths using `$ref`:

```ruby
class UsersAPI < Grape::API
  resource :users do
    route_setting :path_ref, 'UserItemPath'
    route_param :id do
      get { { id: params[:id] } }
    end
  end

  add_swagger_documentation openapi_version: '3.1.0'
end
```

## ComponentsBuilder

`pathItems` is added to the `COMPONENT_KEYS` list to ensure proper inclusion in OpenAPI output.

## Tag Name Description Guard

`TagNameDescription.build` now safely skips path entries that are `$ref` references (i.e., `{ '$ref' => '#/components/pathItems/...' }`), preventing `NoMethodError` when extracting tags from path item references.

## Files Changed

- `lib/grape-swagger/reusable_example.rb` (new)
- `lib/grape-swagger/reusable_request_body.rb` (new)
- `lib/grape-swagger/reusable_path_item.rb` (new)
- `lib/grape-swagger.rb` (requires added)
- `lib/grape-swagger/openapi/components_builder.rb` (`pathItems` added to COMPONENT_KEYS)
- `lib/grape-swagger/doc_methods/tag_name_description.rb` (`$ref` guard added)
- `spec/grape-swagger/reusable_example_spec.rb` (new)
- `spec/grape-swagger/reusable_request_body_spec.rb` (new)
- `spec/grape-swagger/openapi/reusable_path_item_spec.rb` (new)
