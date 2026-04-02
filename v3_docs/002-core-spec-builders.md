# 002: Core Spec Builders

## User Stories

### As a developer, when I configure OpenAPI 3.1.0, the generated spec has the correct top-level structure (openapi, info, servers, components, paths) instead of Swagger 2.0 structure.

**Acceptance criteria:**
- Root object contains `openapi: "3.1.0"` instead of `swagger: "2.0"`
- Info object is properly structured with title, version, description, contact, license
- `servers` array replaces legacy `host`/`basePath`/`schemes` fields
- Multiple server definitions are supported, including server variables
- Backward-compatible conversion from `host`/`basePath`/`schemes` to `servers` array
- `components` object replaces top-level `definitions` and `securityDefinitions`
- `definitions` are moved to `components.schemas`
- `securityDefinitions` are moved to `components.securitySchemes`
- All OpenAPI 3.1.0 component types are supported (schemas, responses, parameters, examples, requestBodies, headers, securitySchemes, links, callbacks)
- Only non-empty component sections are included
- `$ref` paths are translated from `#/definitions/...` to `#/components/schemas/...`
- Optional top-level fields are preserved: security, tags, externalDocs, webhooks
- Paths default to empty hash when not provided

## Components

| Component | Purpose |
|-----------|---------|
| `InfoBuilder` | Builds the `info` object from options; ensures `version` present (defaults to '0.0.1'); adds `x-base-path` extension for backward compat |
| `ServersBuilder` | Converts legacy `host`/`basePath`/`schemes` to `servers` array, or passes through explicit `servers`; defaults to HTTPS |
| `ComponentsBuilder` | Builds `components` object; migrates `definitions` to `schemas`, `securityDefinitions` to `securitySchemes`; only includes non-empty sections |
| `SchemaResolver` | Translates `$ref` paths between Swagger 2.0 and OpenAPI 3.1.0 formats; handles nested schemas recursively |
| `SpecBuilderV3_1` | Orchestrates InfoBuilder, ServersBuilder, ComponentsBuilder; requires `info` in options; assembles complete spec with openapi, info, servers, paths, components, security, tags, externalDocs |
