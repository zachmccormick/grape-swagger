# 003: Reference Validation

## User Stories

### As a developer, when I generate an OpenAPI spec, I can validate that all $ref paths resolve correctly, detect circular references, and get warnings about deprecated Swagger 2.0-style references.

**Acceptance criteria:**
- `ReferenceValidator.validate(spec)` validates all `$ref` paths exist in the specification
- `ReferenceValidator.extract_references(spec)` finds all unique `$ref` values recursively
- Missing references produce errors with context (which schema references the missing target)
- Circular references are detected and reported as warnings
- Self-references (e.g., Tree -> Tree) are allowed by default (`allow_self_reference: true`)
- Complex circular chains (A -> B -> C -> A) are detected
- Deprecated Swagger 2.0-style refs (`#/definitions/...`) in OpenAPI 3.x specs produce warnings
- External file references (`external.json#/...`) are recognized and skipped with a warning
- URL references (`https://...`) are recognized and skipped
- Strict mode (`strict: true`) rejects external references as errors
- Circular reference detection can be disabled (`detect_circular: false`)
- Validation result returns `{ valid:, errors:, warnings: }` hash
- Supports all OpenAPI 3.x component types: schemas, responses, parameters, examples, requestBodies, headers, securitySchemes, links, callbacks
- Also supports legacy Swagger 2.0 definitions, responses, and parameters

### As a developer, SchemaResolver provides recursive schema translation with immutable processing.

**Acceptance criteria:**
- `translate_ref` translates single `$ref` paths between Swagger 2.0 and OpenAPI 3.1.0
- `translate_schema` recursively translates all `$ref` paths within a schema (properties, items, allOf, oneOf, anyOf, not, additionalProperties)
- `translate_components` batch-translates all schemas in a components/definitions hash
- `deep_dup` ensures original schemas are not modified during translation
- External file references are translated correctly
- Already-translated references are not double-translated

## Components

| Component | Purpose |
|-----------|---------|
| `SchemaResolver` | Translates `$ref` paths between Swagger 2.0 and OpenAPI 3.1.0 formats; handles nested schemas recursively with `translate_ref`, `translate_schema`, `translate_components`; uses `deep_dup` for immutable processing |
| `ReferenceValidator` | Validates all `$ref` paths in generated specs; detects missing references with context; detects circular references (allowing self-references); warns about deprecated Swagger 2.0 refs in OpenAPI 3.x; supports external file/URL references; strict mode option |
