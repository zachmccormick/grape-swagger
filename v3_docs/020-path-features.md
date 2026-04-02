# PR 20: Path-Level Features

## Overview

Adds path-level parameter hoisting via the `path_params` DSL, path-level server overrides via `path_servers` route setting, and path-level `$ref` support. These features allow shared parameters to live at the path item level (avoiding duplication across HTTP methods), per-path server overrides, and path item component references.

## Changes

### 1. `path_params` DSL (`endpoint/path_params_extension.rb`)

A `path_params(*param_names)` method is added to `Grape::API` and `Grape::API::Instance`. It stores param names via `route_setting :path_level_param_names`, making them available on each route's settings.

```ruby
namespace :users do
  route_param :user_id, type: Integer, desc: 'User ID' do
    path_params :user_id  # Mark as path-level parameter

    get { ... }   # user_id appears at path level, not here
    put { ... }   # user_id appears at path level, not here
  end
end
```

When multiple path parameters should be shared:

```ruby
route_param :user_id do
  route_param :post_id do
    path_params :user_id, :post_id
    get { ... }
    delete { ... }
  end
end
```

### 2. Path Item Construction (`endpoint.rb`)

The `path_item` method is restructured into two passes:

1. **First pass**: Iterates all routes to collect `path_level_param_names`, `path_ref`, and `path_servers` settings, grouped by path string.
2. **Second pass**: Builds each route's method object. When path-level param names are present, uses `method_object_with_path_params` to build all parameters, extract those marked as path-level, and filter them from individual operations.

Key new methods:
- `method_object_with_path_params(route, options, path, path_level_param_names)` -- returns `[verb, method_object, path_level_params]`
- `params_object_unfiltered(route, options, path, consumes)` -- builds params without path-level filtering
- `finalize_params(parameters, route, path)` -- applies MoveParams and FormatData
- `collect_path_param_names(route)` -- reads `route.settings[:path_level_param_names]`
- `servers_object(route)` -- reads `route.options[:servers]`
- `extract_body_params(parameters)` -- selects body/formData params from an array

### 3. Path-Level Servers

The `path_servers` route setting allows per-path server overrides:

```ruby
namespace :legacy do
  route_setting :path_servers, [{ url: 'https://legacy.example.com' }]
  get { ... }
end
```

The servers array is attached to the path item object.

### 4. Operation-Level Servers

The `servers` route option allows per-operation server overrides:

```ruby
desc 'Get users', servers: [{ url: 'https://api2.example.com' }]
get :users do
  ...
end
```

## Files Changed

| File | Change |
|------|--------|
| `lib/grape-swagger/endpoint/path_params_extension.rb` | New -- `path_params` DSL via `route_setting` |
| `lib/grape-swagger/endpoint.rb` | Two-pass path_item, path-level param extraction, servers support |
| `lib/grape-swagger.rb` | Require for path_params_extension |
| `spec/grape-swagger/endpoint/path_params_extension_spec.rb` | New -- specs for path_params DSL |

## Test Coverage

- Path-level parameter hoisting (single and multiple params)
- Path-level params filtered from individual operations
- Nested route_param with path_params
- Path-level servers
