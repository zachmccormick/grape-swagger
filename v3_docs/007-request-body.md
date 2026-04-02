# PR 7: RequestBody Separation

## User Story

As a developer generating OpenAPI 3.1.0 documentation with grape-swagger,
I want body parameters to be automatically separated from the `parameters` array
and placed into a proper `requestBody` object with `content` and `schema`,
so that POST/PUT/PATCH endpoints produce spec-compliant OpenAPI 3.1.0 output
where request bodies are described under `requestBody` rather than inline parameters.

## Acceptance Criteria

1. **RequestBodyBuilder** extracts body parameters and builds requestBody objects
   - `.build(params, method, consumes, version)` is the main entry point
   - Returns `nil` for Swagger 2.0 (no-op, preserving backward compatibility)
   - Returns `nil` for HTTP methods that don't support request bodies (GET, DELETE, HEAD, OPTIONS)
   - Extracts `in: 'body'` and `in: 'formData'` params from the params array
   - Builds `requestBody` with `content`, `required`, and `description` fields
   - For this PR, hardcodes `application/json` as the content type (PR 10 adds ContentNegotiator)
   - Builds schema from body params: single $ref, single type, multi-param merge, form data
   - Includes Phase 6 schema field enhancements: title, not, enum, default, readOnly,
     writeOnly, minProperties, maxProperties, externalDocs, description
   - Supports single example and named examples extraction

2. **Endpoint integration** detects OpenAPI version and applies requestBody building
   - `method_object` detects OpenAPI 3.1.0 via VersionSelector
   - For OpenAPI 3.1.0, calls RequestBodyBuilder.build with body params
   - Removes body params from the `parameters` array after extraction
   - All existing Swagger 2.0 behavior is completely unchanged

3. **FormatData fixes** handle $ref parameters safely
   - Filters out `$ref` parameters (component references without `:name` or `:in`)
   - Uses nil-safe name access: `p[:name]&.start_with?` instead of `p[:name].start_with?`

## Design Notes

- RequestBodyBuilder is a standalone class with class methods (no instance state)
- Endpoint changes are minimal: version detection + requestBody building only
- This is NOT the full two-pass architecture (that comes in PRs 8, 9, 20)
- ContentNegotiator is NOT used yet; `application/json` is hardcoded (PR 10 adds it)
