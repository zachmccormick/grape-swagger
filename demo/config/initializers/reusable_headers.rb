# frozen_string_literal: true

# Reusable Header definitions using the grape-swagger DSL
# These demonstrate the Header Object from OpenAPI 3.1.0
# See: https://spec.openapis.org/oas/v3.1.0#header-object

# Rate limiting headers - commonly used in API responses
class RateLimitLimitHeader < GrapeSwagger::ReusableHeader
  description 'The maximum number of requests allowed in the current time window'
  schema type: 'integer', example: 1000
  required false
end

class RateLimitRemainingHeader < GrapeSwagger::ReusableHeader
  description 'The number of requests remaining in the current time window'
  schema type: 'integer', example: 999
  required false
end

class RateLimitResetHeader < GrapeSwagger::ReusableHeader
  description 'The time at which the rate limit window resets (Unix timestamp)'
  schema type: 'integer', format: 'int64', example: 1640995200
  required false
end

# Pagination headers - useful for paginated list responses
class XTotalCountHeader < GrapeSwagger::ReusableHeader
  description 'Total number of items available'
  schema type: 'integer', example: 150
  required false
end

class XTotalPagesHeader < GrapeSwagger::ReusableHeader
  description 'Total number of pages available'
  schema type: 'integer', example: 8
  required false
end

class XCurrentPageHeader < GrapeSwagger::ReusableHeader
  description 'Current page number'
  schema type: 'integer', example: 1
  required false
end

class XNextPageHeader < GrapeSwagger::ReusableHeader
  description 'URL for the next page of results (null if on last page)'
  schema type: 'string', format: 'uri', example: 'https://api.example.com/pets?page=2'
  required false
end

# Request tracking headers
class XRequestIdHeader < GrapeSwagger::ReusableHeader
  description 'Unique identifier for this request, useful for debugging and support'
  schema type: 'string', format: 'uuid', example: '550e8400-e29b-41d4-a716-446655440000'
  required false
end

# Deprecation header (for deprecated endpoints)
class DeprecationHeader < GrapeSwagger::ReusableHeader
  description 'Indicates this endpoint is deprecated and when it will be removed'
  schema type: 'string', example: 'This endpoint is deprecated and will be removed on 2025-12-01'
  deprecated true
  required false
end

# Cache control header
class CacheControlHeader < GrapeSwagger::ReusableHeader
  description 'Caching directives for the response'
  schema type: 'string', example: 'max-age=3600, public'
  required false
end

# ETag header for conditional requests
class ETagHeader < GrapeSwagger::ReusableHeader
  description 'Entity tag for cache validation'
  schema type: 'string', example: '"33a64df551425fcc55e4d42a148795d9f25f89d4"'
  required false
end
