# PR 1: Version Management System - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable grape-swagger to detect, validate, and select between Swagger 2.0 and OpenAPI 3.1.0 spec versions, defaulting to Swagger 2.0 for full backward compatibility.

**Architecture:** Four small classes under `GrapeSwagger::OpenAPI` namespace: `VersionConstants` (supported version strings), `Errors::UnsupportedVersionError` (custom exception), `Version` (version object with predicates), and `VersionSelector` (detection/validation/building entry point). A user story document at `v3_docs/001-version-management.md` describes the feature.

**Tech Stack:** Ruby, RSpec, Grape

**Baseline:** 478 tests passing, 0 failures on master. All tests must continue to pass after each task.

---

### Task 1: Write the user story document

**Files:**
- Create: `v3_docs/001-version-management.md`

- [ ] **Step 1: Create directories and write the user story**

```bash
mkdir -p v3_docs
```

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add v3_docs/001-version-management.md
git commit -m "docs: add user story for version management system (PR 1)"
```

---

### Task 2: VersionConstants module

**Files:**
- Create: `lib/grape-swagger/openapi/version_constants.rb`
- Test: `spec/grape-swagger/openapi/version_constants_spec.rb`

- [ ] **Step 1: Create directories and write the failing test**

```bash
mkdir -p lib/grape-swagger/openapi spec/grape-swagger/openapi
```

```ruby
# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::VersionConstants do
  it 'defines SWAGGER_2_0 as 2.0' do
    expect(described_class::SWAGGER_2_0).to eq('2.0')
  end

  it 'defines OPENAPI_3_1_0 as 3.1.0' do
    expect(described_class::OPENAPI_3_1_0).to eq('3.1.0')
  end

  it 'defines SUPPORTED_VERSIONS containing both versions' do
    expect(described_class::SUPPORTED_VERSIONS).to contain_exactly('2.0', '3.1.0')
  end

  it 'freezes SUPPORTED_VERSIONS to prevent modification' do
    expect(described_class::SUPPORTED_VERSIONS).to be_frozen
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/openapi/version_constants_spec.rb --format documentation`
Expected: FAIL - `uninitialized constant GrapeSwagger::OpenAPI`

- [ ] **Step 3: Write the implementation**

```ruby
# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module VersionConstants
      SWAGGER_2_0 = '2.0'
      OPENAPI_3_1_0 = '3.1.0'

      SUPPORTED_VERSIONS = [SWAGGER_2_0, OPENAPI_3_1_0].freeze
    end
  end
end
```

- [ ] **Step 4: Add require to grape-swagger.rb**

In `lib/grape-swagger.rb`, add after the `require 'grape-swagger/token_owner_resolver'` line:

```ruby
require 'grape-swagger/openapi/version_constants'
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/openapi/version_constants_spec.rb --format documentation`
Expected: 4 examples, 0 failures

- [ ] **Step 6: Run full suite to verify no regressions**

Run: `bundle exec rspec`
Expected: 482 examples, 0 failures

- [ ] **Step 7: Commit**

```bash
git add lib/grape-swagger/openapi/version_constants.rb spec/grape-swagger/openapi/version_constants_spec.rb lib/grape-swagger.rb
git commit -m "feat: add VersionConstants module for OpenAPI version definitions"
```

---

### Task 3: UnsupportedVersionError

**Files:**
- Create: `lib/grape-swagger/openapi/errors.rb`
- Test: `spec/grape-swagger/openapi/errors_spec.rb`

Note: This file is at `lib/grape-swagger/openapi/errors.rb` under the `GrapeSwagger::OpenAPI::Errors` namespace. It coexists with the existing `lib/grape-swagger/errors.rb` under `GrapeSwagger::Errors`.

- [ ] **Step 1: Write the failing test**

```ruby
# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError do
  it 'is a StandardError' do
    expect(described_class).to be < StandardError
  end

  it 'includes the invalid version in the message' do
    error = described_class.new('4.0.0', ['2.0', '3.1.0'])
    expect(error.message).to include('4.0.0')
  end

  it 'includes supported versions in the message' do
    error = described_class.new('4.0.0', ['2.0', '3.1.0'])
    expect(error.message).to include('2.0')
    expect(error.message).to include('3.1.0')
  end

  it 'handles nil version gracefully' do
    error = described_class.new(nil, ['2.0', '3.1.0'])
    expect(error.message).to include('Unsupported OpenAPI version')
    expect(error.message).to include('2.0')
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/openapi/errors_spec.rb --format documentation`
Expected: FAIL - `uninitialized constant GrapeSwagger::OpenAPI::Errors`

- [ ] **Step 3: Write the implementation**

```ruby
# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Errors
      class UnsupportedVersionError < StandardError
        def initialize(version = nil, supported = [])
          message = if version.nil?
                      "Unsupported OpenAPI version. Supported versions: #{supported.join(', ')}"
                    else
                      "Unsupported OpenAPI version: #{version}. Supported versions: #{supported.join(', ')}"
                    end
          super(message)
        end
      end
    end
  end
end
```

- [ ] **Step 4: Add require to grape-swagger.rb**

In `lib/grape-swagger.rb`, add after the `version_constants` require:

```ruby
require 'grape-swagger/openapi/errors'
```

Note: This does NOT conflict with the existing `require 'grape-swagger/errors'` (which is `GrapeSwagger::Errors`). These are different namespaces.

- [ ] **Step 5: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/openapi/errors_spec.rb --format documentation`
Expected: 4 examples, 0 failures

- [ ] **Step 6: Run full suite to verify no regressions**

Run: `bundle exec rspec`
Expected: 486 examples, 0 failures

- [ ] **Step 7: Commit**

```bash
git add lib/grape-swagger/openapi/errors.rb spec/grape-swagger/openapi/errors_spec.rb lib/grape-swagger.rb
git commit -m "feat: add UnsupportedVersionError for invalid version handling"
```

---

### Task 4: Version class

**Files:**
- Create: `lib/grape-swagger/openapi/version.rb`
- Test: `spec/grape-swagger/openapi/version_spec.rb`

Note: This file is at `lib/grape-swagger/openapi/version.rb` under `GrapeSwagger::OpenAPI::Version`. It coexists with the existing `lib/grape-swagger/version.rb` (which defines `GrapeSwagger::VERSION` as a string constant).

- [ ] **Step 1: Write the failing test**

```ruby
# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::Version do
  describe '#initialize' do
    it 'stores version_string' do
      version = described_class.new('2.0')
      expect(version.version_string).to eq('2.0')
    end

    it 'stores options' do
      options = { info: { title: 'Test API' } }
      version = described_class.new('2.0', options)
      expect(version.options).to eq(options)
    end

    it 'defaults options to empty hash' do
      version = described_class.new('2.0')
      expect(version.options).to eq({})
    end
  end

  describe '#swagger_2_0?' do
    it 'returns true for 2.0' do
      version = described_class.new('2.0')
      expect(version.swagger_2_0?).to be true
    end

    it 'returns false for 3.1.0' do
      version = described_class.new('3.1.0')
      expect(version.swagger_2_0?).to be false
    end
  end

  describe '#openapi_3_1_0?' do
    it 'returns true for 3.1.0' do
      version = described_class.new('3.1.0')
      expect(version.openapi_3_1_0?).to be true
    end

    it 'returns false for 2.0' do
      version = described_class.new('2.0')
      expect(version.openapi_3_1_0?).to be false
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/openapi/version_spec.rb --format documentation`
Expected: FAIL - `uninitialized constant GrapeSwagger::OpenAPI::Version` (the module exists from Task 2, but not this class)

- [ ] **Step 3: Write the implementation**

```ruby
# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class Version
      attr_reader :version_string, :options

      def initialize(version_string, options = {})
        @version_string = version_string
        @options = options
      end

      def swagger_2_0?
        version_string == VersionConstants::SWAGGER_2_0
      end

      def openapi_3_1_0?
        version_string == VersionConstants::OPENAPI_3_1_0
      end
    end
  end
end
```

- [ ] **Step 4: Add require to grape-swagger.rb**

In `lib/grape-swagger.rb`, add after the `openapi/errors` require:

```ruby
require 'grape-swagger/openapi/version'
```

Note: This does NOT conflict with the existing `require 'grape-swagger/version'` (which defines `GrapeSwagger::VERSION = '2.1.3'`). Different paths, different constants.

- [ ] **Step 5: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/openapi/version_spec.rb --format documentation`
Expected: 7 examples, 0 failures

- [ ] **Step 6: Run full suite to verify no regressions**

Run: `bundle exec rspec`
Expected: 493 examples, 0 failures

- [ ] **Step 7: Commit**

```bash
git add lib/grape-swagger/openapi/version.rb spec/grape-swagger/openapi/version_spec.rb lib/grape-swagger.rb
git commit -m "feat: add Version class with spec version predicates"
```

---

### Task 5: VersionSelector class

**Files:**
- Create: `lib/grape-swagger/openapi/version_selector.rb`
- Test: `spec/grape-swagger/openapi/version_selector_spec.rb`

- [ ] **Step 1: Write the failing test**

```ruby
# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::VersionSelector do
  describe '.detect_version' do
    context 'when openapi_version is specified' do
      it 'returns the specified openapi_version' do
        options = { openapi_version: '3.1.0' }
        expect(described_class.detect_version(options)).to eq('3.1.0')
      end
    end

    context 'when swagger_version is specified' do
      it 'returns swagger_version for backward compatibility' do
        options = { swagger_version: '2.0' }
        expect(described_class.detect_version(options)).to eq('2.0')
      end
    end

    context 'when no version is specified' do
      it 'defaults to Swagger 2.0' do
        expect(described_class.detect_version({})).to eq('2.0')
      end
    end

    context 'when both openapi_version and swagger_version are specified' do
      it 'prioritizes openapi_version over swagger_version' do
        options = { openapi_version: '3.1.0', swagger_version: '2.0' }
        expect(described_class.detect_version(options)).to eq('3.1.0')
      end
    end
  end

  describe '.validate_version' do
    it 'accepts 2.0' do
      expect { described_class.validate_version('2.0') }.not_to raise_error
    end

    it 'accepts 3.1.0' do
      expect { described_class.validate_version('3.1.0') }.not_to raise_error
    end

    it 'raises UnsupportedVersionError for invalid version' do
      expect { described_class.validate_version('1.0') }
        .to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
    end

    it 'raises UnsupportedVersionError for nil version' do
      expect { described_class.validate_version(nil) }
        .to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
    end

    it 'includes supported versions in error message' do
      expect { described_class.validate_version('4.0.0') }
        .to raise_error(/2\.0.*3\.1\.0/)
    end
  end

  describe '.supported_versions' do
    it 'returns an array containing 2.0 and 3.1.0' do
      versions = described_class.supported_versions
      expect(versions).to contain_exactly('2.0', '3.1.0')
    end
  end

  describe '.build_spec' do
    it 'returns a Version object for Swagger 2.0 by default' do
      spec = described_class.build_spec({})
      expect(spec).to be_a(GrapeSwagger::OpenAPI::Version)
      expect(spec.version_string).to eq('2.0')
      expect(spec.swagger_2_0?).to be true
    end

    it 'returns a Version object for OpenAPI 3.1.0 when specified' do
      spec = described_class.build_spec(openapi_version: '3.1.0')
      expect(spec.version_string).to eq('3.1.0')
      expect(spec.openapi_3_1_0?).to be true
    end

    it 'raises UnsupportedVersionError for invalid version' do
      expect { described_class.build_spec(openapi_version: '4.0.0') }
        .to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
    end

    it 'passes options through to the version object' do
      options = { openapi_version: '3.1.0', info: { title: 'Test API' } }
      spec = described_class.build_spec(options)
      expect(spec.options).to eq(options)
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/openapi/version_selector_spec.rb --format documentation`
Expected: FAIL - `uninitialized constant GrapeSwagger::OpenAPI::VersionSelector`

- [ ] **Step 3: Write the implementation**

```ruby
# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class VersionSelector
      include VersionConstants

      def self.detect_version(options)
        return options[:openapi_version] if options[:openapi_version]
        return options[:swagger_version] if options[:swagger_version]

        SWAGGER_2_0
      end

      def self.validate_version(version)
        return if SUPPORTED_VERSIONS.include?(version)

        raise Errors::UnsupportedVersionError.new(version, SUPPORTED_VERSIONS)
      end

      def self.supported_versions
        SUPPORTED_VERSIONS
      end

      def self.build_spec(options)
        version = detect_version(options)
        validate_version(version)
        Version.new(version, options)
      end
    end
  end
end
```

- [ ] **Step 4: Add require to grape-swagger.rb**

In `lib/grape-swagger.rb`, add after the `openapi/version` require:

```ruby
require 'grape-swagger/openapi/version_selector'
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/openapi/version_selector_spec.rb --format documentation`
Expected: 14 examples, 0 failures

- [ ] **Step 6: Run full suite to verify no regressions**

Run: `bundle exec rspec`
Expected: 507 examples, 0 failures

- [ ] **Step 7: Commit**

```bash
git add lib/grape-swagger/openapi/version_selector.rb spec/grape-swagger/openapi/version_selector_spec.rb lib/grape-swagger.rb
git commit -m "feat: add VersionSelector for version detection and validation"
```

---

### Task 6: Integration test

**Files:**
- Create: `spec/grape-swagger/openapi/integration_spec.rb`

- [ ] **Step 1: Write the integration test**

This test verifies the complete workflow: all components accessible, version detection works end-to-end, backward compatibility preserved.

```ruby
# frozen_string_literal: true

require 'spec_helper'

describe 'Version Management System Integration' do
  describe 'module accessibility' do
    it 'exposes VersionSelector from GrapeSwagger::OpenAPI' do
      expect(GrapeSwagger::OpenAPI::VersionSelector).to be_a(Class)
    end

    it 'exposes Version from GrapeSwagger::OpenAPI' do
      expect(GrapeSwagger::OpenAPI::Version).to be_a(Class)
    end

    it 'exposes VersionConstants from GrapeSwagger::OpenAPI' do
      expect(GrapeSwagger::OpenAPI::VersionConstants).to be_a(Module)
    end

    it 'exposes UnsupportedVersionError from GrapeSwagger::OpenAPI::Errors' do
      expect(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError).to be < StandardError
    end
  end

  describe 'complete workflow' do
    it 'defaults to Swagger 2.0 when no version specified' do
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec({})
      expect(version.version_string).to eq('2.0')
      expect(version.swagger_2_0?).to be true
      expect(version.openapi_3_1_0?).to be false
    end

    it 'selects OpenAPI 3.1.0 when specified' do
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(openapi_version: '3.1.0')
      expect(version.version_string).to eq('3.1.0')
      expect(version.openapi_3_1_0?).to be true
      expect(version.swagger_2_0?).to be false
    end

    it 'respects backward compatibility with swagger_version' do
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(swagger_version: '2.0')
      expect(version.version_string).to eq('2.0')
    end

    it 'prioritizes openapi_version over swagger_version' do
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(
        openapi_version: '3.1.0',
        swagger_version: '2.0'
      )
      expect(version.openapi_3_1_0?).to be true
    end

    it 'rejects unsupported versions with helpful error' do
      expect do
        GrapeSwagger::OpenAPI::VersionSelector.build_spec(openapi_version: '4.0.0')
      end.to raise_error(
        GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError,
        /4\.0\.0.*2\.0.*3\.1\.0/
      )
    end

    it 'preserves options on the version object' do
      options = { openapi_version: '3.1.0', info: { title: 'My API' } }
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(options)
      expect(version.options[:info]).to eq(title: 'My API')
    end
  end
end
```

- [ ] **Step 2: Run integration test**

Run: `bundle exec rspec spec/grape-swagger/openapi/integration_spec.rb --format documentation`
Expected: 10 examples, 0 failures

- [ ] **Step 3: Run full suite**

Run: `bundle exec rspec`
Expected: 517 examples, 0 failures

- [ ] **Step 4: Commit**

```bash
git add spec/grape-swagger/openapi/integration_spec.rb
git commit -m "test: add version management integration tests"
```

---

### Task 7: Demo app scaffold

**Files:**
- Create: `demo/api.rb`
- Create: `demo/config.ru`
- Create: `demo/Gemfile`
- Test: `spec/openapi_v3_1/demo_smoke_spec.rb`

This creates the minimal demo app that will grow incrementally across all 24 PRs. For PR 1, it simply demonstrates configuring `openapi_version: '3.1.0'`.

- [ ] **Step 1: Create demo Gemfile**

```ruby
# frozen_string_literal: true

source 'https://rubygems.org'

gem 'grape'
gem 'grape-swagger', path: '..'
gem 'grape-entity'
gem 'grape-swagger-entity'
gem 'rack'
```

- [ ] **Step 2: Create demo API**

```ruby
# frozen_string_literal: true

require 'grape'
require 'grape-swagger'

class DemoAPI < Grape::API
  format :json

  desc 'Health check'
  get :status do
    { status: 'ok' }
  end

  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'Demo API',
      description: 'Progressive demo for OpenAPI 3.1.0 features',
      version: '1.0.0'
    }
  )
end
```

- [ ] **Step 3: Create config.ru**

```ruby
# frozen_string_literal: true

require_relative 'api'

run DemoAPI
```

- [ ] **Step 4: Write demo smoke test**

```ruby
# frozen_string_literal: true

require 'spec_helper'

# Minimal demo API for smoke testing OpenAPI 3.1.0 configuration
class DemoSmokeAPI < Grape::API
  format :json

  desc 'Health check'
  get :status do
    { status: 'ok' }
  end

  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'Demo API',
      description: 'Smoke test API',
      version: '1.0.0'
    }
  )
end

describe 'Demo API smoke test' do
  def app
    DemoSmokeAPI
  end

  it 'accepts openapi_version 3.1.0 without error' do
    expect { DemoSmokeAPI }.not_to raise_error
  end

  it 'still serves swagger doc endpoint' do
    get '/swagger_doc'
    expect(last_response.status).to eq(200)
  end
end
```

- [ ] **Step 5: Create spec directory and run test**

```bash
mkdir -p spec/openapi_v3_1
```

Run: `bundle exec rspec spec/openapi_v3_1/demo_smoke_spec.rb --format documentation`
Expected: 2 examples, 0 failures

- [ ] **Step 6: Run full suite**

Run: `bundle exec rspec`
Expected: 519 examples, 0 failures

- [ ] **Step 7: Commit**

```bash
git add demo/api.rb demo/config.ru demo/Gemfile spec/openapi_v3_1/demo_smoke_spec.rb
git commit -m "feat: add demo app scaffold for OpenAPI 3.1.0"
```

---

### Task 8: Final verification

- [ ] **Step 1: Run the full test suite one final time**

Run: `bundle exec rspec`
Expected: 519 examples, 0 failures, 2 pending

- [ ] **Step 2: Verify file structure**

Run: `find lib/grape-swagger/openapi spec/grape-swagger/openapi spec/openapi_v3_1 v3_docs demo/api.rb demo/config.ru demo/Gemfile -type f 2>/dev/null | sort`

Expected output:
```
demo/api.rb
demo/config.ru
demo/Gemfile
lib/grape-swagger/openapi/errors.rb
lib/grape-swagger/openapi/version.rb
lib/grape-swagger/openapi/version_constants.rb
lib/grape-swagger/openapi/version_selector.rb
spec/grape-swagger/openapi/errors_spec.rb
spec/grape-swagger/openapi/integration_spec.rb
spec/grape-swagger/openapi/version_constants_spec.rb
spec/grape-swagger/openapi/version_spec.rb
spec/grape-swagger/openapi/version_selector_spec.rb
spec/openapi_v3_1/demo_smoke_spec.rb
v3_docs/001-version-management.md
```

- [ ] **Step 3: Verify grape-swagger.rb has all requires**

Run: `grep 'openapi/' lib/grape-swagger.rb`

Expected output:
```
require 'grape-swagger/openapi/version_constants'
require 'grape-swagger/openapi/errors'
require 'grape-swagger/openapi/version'
require 'grape-swagger/openapi/version_selector'
```

- [ ] **Step 4: Verify no existing tests broke**

Run: `bundle exec rspec spec/swagger_v2/ spec/issues/ spec/version_spec.rb`
Expected: All pass (these are the original Swagger 2.0 tests)
