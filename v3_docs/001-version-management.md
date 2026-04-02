# 001: Version Management System

## User Stories

### As a developer using grape-swagger, I want to specify `openapi_version: '3.1.0'` so that my API generates OpenAPI 3.1.0 documentation.

**Acceptance criteria:**
- When `openapi_version: '3.1.0'` is passed to `add_swagger_documentation`, the system recognizes OpenAPI 3.1.0 mode
- When no version is specified, the system defaults to Swagger 2.0 (backward compatible)
- When `swagger_version: '2.0'` is passed (legacy), the system uses Swagger 2.0
- When both `openapi_version` and `swagger_version` are specified, `openapi_version` takes precedence
- When an unsupported version is specified, a clear error is raised listing supported versions

### As a developer building grape-swagger internals, I want version predicate methods so that I can branch behavior based on the target spec version.

**Acceptance criteria:**
- `version.swagger_2_0?` returns true/false
- `version.openapi_3_1_0?` returns true/false
- The version object carries the original options for downstream use

## Components

| Component | Purpose |
|-----------|---------|
| `VersionConstants` | Defines supported version strings as frozen constants |
| `UnsupportedVersionError` | Custom error with helpful message listing valid versions |
| `Version` | Value object wrapping a version string with predicate methods |
| `VersionSelector` | Entry point: detect, validate, and build Version objects |
