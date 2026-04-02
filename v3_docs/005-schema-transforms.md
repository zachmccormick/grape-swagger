# 005: Schema Transformation Pipeline

## User Stories

### As a developer, when generating OpenAPI 3.x specs, definitions are automatically placed under `components/schemas` instead of top-level `definitions`.

**Acceptance criteria:**
- When `output[:openapi]` starts with `'3.'`, definitions are placed under `output[:components][:schemas]`
- When generating Swagger 2.0 specs, definitions remain at `output[:definitions]` (existing behavior preserved)
- Existing `components` hash is preserved and merged if already present

### As a developer, all `$ref` paths are automatically transformed from `#/definitions/` to `#/components/schemas/` for OpenAPI 3.x specs.

**Acceptance criteria:**
- `transform_definition_refs!(obj)` recursively walks the spec hash
- All `$ref` string values starting with `#/definitions/` are rewritten to `#/components/schemas/`
- Works with both symbol and string keys
- Handles nested hashes and arrays
- Non-matching `$ref` values are left unchanged

### As a developer, `type: file` is automatically transformed to `type: string, format: binary` for OpenAPI 3.x specs.

**Acceptance criteria:**
- `transform_file_types!(obj)` recursively walks the spec hash
- Any `type: 'file'` is replaced with `type: 'string', format: 'binary'`
- Works with both symbol and string keys
- Handles nested hashes and arrays

### As a developer, tag objects with snake_case keys are normalized to camelCase.

**Acceptance criteria:**
- `normalize_tag(tag)` converts `external_docs` key to `externalDocs`
- Original tag hash is not mutated (returns a copy)
- Tags without `external_docs` are returned unchanged
- Tags that already have `externalDocs` are not double-converted

## Components

| Component | Purpose |
|-----------|---------|
| `output_path_definitions` (modified) | Version-aware branching: places definitions under `components/schemas` for OpenAPI 3.x, applies ref and file type transforms |
| `transform_definition_refs!` | Recursively converts `#/definitions/` refs to `#/components/schemas/` |
| `transform_file_types!` | Recursively converts `type: file` to `type: string, format: binary` |
| `normalize_tag` | Converts snake_case tag keys to camelCase (`external_docs` -> `externalDocs`) |
| `tags_from` (modified) | Applies `normalize_tag` to custom tags |
