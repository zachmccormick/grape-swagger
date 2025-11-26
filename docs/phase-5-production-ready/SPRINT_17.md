# Sprint 17: Release Preparation
## Phase 5 - Production Ready

### Sprint Overview
**Duration**: 3 days
**Sprint Goal**: Complete final testing, security audit, and prepare the release candidate for OpenAPI 3.1.0 support.

### User Stories

#### Story 17.1: Regression Testing
**As a** maintainer
**I want** comprehensive regression tests
**So that** existing functionality is preserved

**Acceptance Criteria**:
- [ ] All existing tests pass
- [ ] Edge cases covered
- [ ] Real-world API scenarios tested
- [ ] Version switching verified
- [ ] Backward compatibility confirmed

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Existing Swagger 2.0 APIs unchanged
- Mixed version configuration works
- Version detection accurate
- All documentation formats supported
- Entity inheritance preserved
```

#### Story 17.2: Security Audit
**As a** security-conscious user
**I want** the library to be secure
**So that** my API specs are safe

**Acceptance Criteria**:
- [ ] No code injection vulnerabilities
- [ ] Input sanitization verified
- [ ] Dependency audit completed
- [ ] Security headers documented
- [ ] Sensitive data handling verified

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Malicious input sanitized
- XSS prevention in descriptions
- Path traversal prevented
- Dependency versions secure
- No information leakage
```

#### Story 17.3: Release Notes
**As a** user
**I want** clear release notes
**So that** I understand what changed

**Acceptance Criteria**:
- [ ] Changelog updated
- [ ] Breaking changes highlighted
- [ ] New features listed
- [ ] Bug fixes documented
- [ ] Migration notes included

**TDD Tests Required**:
```ruby
# Validation tests:
- Changelog format valid
- Version numbers consistent
- All PRs referenced
- Links working
```

#### Story 17.4: Release Candidate
**As a** maintainer
**I want** a tested release candidate
**So that** the release is reliable

**Acceptance Criteria**:
- [ ] Version bumped correctly
- [ ] Gem builds successfully
- [ ] Installation tested
- [ ] CI/CD green
- [ ] Documentation deployed

**TDD Tests Required**:
```ruby
# Integration tests:
- Gem installs without errors
- Basic functionality works post-install
- Dependencies resolved correctly
- All platforms supported
```

### Technical Implementation

#### Regression Test Suite
```ruby
RSpec.describe 'OpenAPI 3.1.0 Regression Suite' do
  describe 'backward compatibility' do
    it 'generates identical Swagger 2.0 when version not specified' do
      # Ensure default behavior unchanged
    end

    it 'handles existing swagger_doc configurations' do
      # Test all legacy config options
    end

    it 'preserves entity documentation' do
      # Entity inheritance still works
    end
  end

  describe 'real-world scenarios' do
    it 'handles complex nested entities' do
      # Deep nesting with references
    end

    it 'generates valid spec for 100+ endpoints' do
      # Large API stress test
    end

    it 'supports all HTTP methods' do
      # GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD
    end
  end

  describe 'version switching' do
    it 'switches cleanly between versions' do
      # Generate 2.0, then 3.1.0, verify both valid
    end

    it 'caches correctly per version' do
      # No cache pollution between versions
    end
  end
end
```

#### Security Test Suite
```ruby
RSpec.describe 'Security Tests' do
  describe 'input sanitization' do
    it 'sanitizes malicious description content' do
      malicious = '<script>alert("xss")</script>'
      # Verify sanitization or escaping
    end

    it 'prevents path traversal in refs' do
      malicious_ref = '../../../etc/passwd'
      # Verify ref validation
    end

    it 'validates URL formats' do
      malicious_url = 'javascript:alert(1)'
      # Verify URL validation
    end
  end

  describe 'dependency security' do
    it 'has no known vulnerabilities' do
      # Run bundle audit
    end

    it 'pins dependencies appropriately' do
      # Verify gemspec constraints
    end
  end
end
```

#### Changelog Template
```markdown
# Changelog

## [2.2.0] - 2025-XX-XX

### Added
- Full OpenAPI 3.1.0 support with `openapi_version: '3.1.0'` option
- Webhooks documentation via `webhooks` configuration
- Callbacks for async operations
- Links for operation chaining
- Enhanced security schemes (OAuth2 flows, OpenID Connect, mTLS)
- JSON Schema 2020-12 alignment
  - Nullable types as type arrays
  - contentEncoding for binary data
  - Conditional schemas (if/then/else)
  - Pattern properties
- Discriminator with mapping for polymorphic schemas
- oneOf/anyOf/allOf schema composition
- Performance optimizations with optional caching

### Changed
- Default version remains Swagger 2.0 for backward compatibility
- Improved type mapping for JSON Schema compliance

### Fixed
- [List any bug fixes]

### Migration
See MIGRATION.md for detailed upgrade instructions.

### Breaking Changes
None - full backward compatibility maintained.
```

#### Release Checklist
```markdown
# Release Checklist v2.2.0

## Pre-Release
- [ ] All tests passing on CI
- [ ] RuboCop violations resolved
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in version.rb
- [ ] Migration guide reviewed
- [ ] Security audit completed

## Build
- [ ] `gem build grape-swagger.gemspec` succeeds
- [ ] Gem file size reasonable
- [ ] No unnecessary files included

## Testing
- [ ] `gem install ./grape-swagger-2.2.0.gem` works
- [ ] Basic smoke test passes
- [ ] Example apps work with new gem

## Release
- [ ] Git tag created: v2.2.0
- [ ] GitHub release created with notes
- [ ] Gem pushed to RubyGems
- [ ] Documentation site updated

## Post-Release
- [ ] Announcement posted
- [ ] Monitor for issues
- [ ] Respond to feedback
```

### Version Configuration

```ruby
# lib/grape-swagger/version.rb
module GrapeSwagger
  VERSION = '2.2.0'

  OPENAPI_VERSIONS = {
    '2.0' => 'Swagger 2.0',
    '3.1.0' => 'OpenAPI 3.1.0'
  }.freeze

  DEFAULT_OPENAPI_VERSION = '2.0'
end
```

### CI/CD Verification

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Run tests
        run: bundle exec rspec

      - name: Build gem
        run: gem build grape-swagger.gemspec

      - name: Publish to RubyGems
        run: gem push *.gem
        env:
          GEM_HOST_API_KEY: ${{ secrets.RUBYGEMS_API_KEY }}
```

### Definition of Done
- [ ] TDD: All RED tests written
- [ ] TDD: All tests GREEN
- [ ] TDD: Code refactored
- [ ] Regression suite passing
- [ ] Security audit complete
- [ ] Release notes written
- [ ] RC build successful
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 8
- **Estimated Hours**: 24
- **Risk Level**: Low
- **Dependencies**: Sprints 15-16 complete

### Phase 5 Completion Checklist
After Sprint 17, Phase 5 should have:
- [ ] Performance benchmarks met
- [ ] Caching implemented
- [ ] Documentation complete
- [ ] Migration guide ready
- [ ] Examples working
- [ ] Regression tests passing
- [ ] Security audit passed
- [ ] Release candidate ready
- [ ] All tests passing
- [ ] Ready for release

---

**Project Complete**: After Sprint 17, grape-swagger will have full OpenAPI 3.1.0 support ready for production release.
