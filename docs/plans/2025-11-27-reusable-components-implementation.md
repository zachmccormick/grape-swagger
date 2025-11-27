# Reusable Components Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add auto-generation and referencing support for OpenAPI reusable components (parameters, responses, headers) using Grape::Entity-style class DSL.

**Architecture:** Three new base classes (ReusableParameter, ReusableResponse, ReusableHeader) that auto-register via Ruby's `inherited` hook into a central GrapeSwagger::Components registry. Endpoint DSL extended with `ref` method to reference components while maintaining Grape runtime validation.

**Tech Stack:** Ruby, RSpec, Grape, grape-swagger OpenAPI 3.1.0

**Design Doc:** `docs/plans/2025-11-27-reusable-components-design.md`

---

## Task 1: Components Registry

**Files:**
- Create: `lib/grape-swagger/components_registry.rb`
- Test: `spec/grape-swagger/components_registry_spec.rb`

**Step 1: Write the failing test for registry basics**

```ruby
# spec/grape-swagger/components_registry_spec.rb
# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::ComponentsRegistry do
  before(:each) do
    described_class.reset!
  end

  describe '.register_parameter' do
    it 'registers a parameter class by name' do
      mock_class = Class.new do
        def self.name
          'PageParam'
        end

        def self.component_name
          nil
        end

        def self.to_openapi
          { name: 'page', in: 'query', schema: { type: 'integer' } }
        end
      end

      described_class.register_parameter(mock_class)

      expect(described_class.parameters).to have_key('PageParam')
      expect(described_class.parameters['PageParam']).to eq(mock_class)
    end
  end

  describe '.register_response' do
    it 'registers a response class by name' do
      mock_class = Class.new do
        def self.name
          'NotFoundResponse'
        end

        def self.component_name
          nil
        end

        def self.to_openapi
          { description: 'Not found' }
        end
      end

      described_class.register_response(mock_class)

      expect(described_class.responses).to have_key('NotFoundResponse')
    end
  end

  describe '.register_header' do
    it 'registers a header class by name' do
      mock_class = Class.new do
        def self.name
          'RateLimitHeader'
        end

        def self.component_name
          nil
        end

        def self.to_openapi
          { description: 'Rate limit', schema: { type: 'integer' } }
        end
      end

      described_class.register_header(mock_class)

      expect(described_class.headers).to have_key('RateLimitHeader')
    end
  end

  describe '.reset!' do
    it 'clears all registries' do
      mock_class = Class.new do
        def self.name
          'TestParam'
        end

        def self.component_name
          nil
        end
      end

      described_class.register_parameter(mock_class)
      described_class.reset!

      expect(described_class.parameters).to be_empty
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/components_registry_spec.rb -v`
Expected: FAIL with "uninitialized constant GrapeSwagger::ComponentsRegistry"

**Step 3: Write minimal implementation**

```ruby
# lib/grape-swagger/components_registry.rb
# frozen_string_literal: true

module GrapeSwagger
  class ComponentsRegistry
    class << self
      def parameters
        @parameters ||= {}
      end

      def responses
        @responses ||= {}
      end

      def headers
        @headers ||= {}
      end

      def register_parameter(klass)
        name = component_name_for(klass)
        parameters[name] = klass
      end

      def register_response(klass)
        name = component_name_for(klass)
        responses[name] = klass
      end

      def register_header(klass)
        name = component_name_for(klass)
        headers[name] = klass
      end

      def component_name_for(klass)
        klass.component_name || klass.name.split('::').last
      end

      def reset!
        @parameters = {}
        @responses = {}
        @headers = {}
      end
    end
  end
end
```

**Step 4: Require in main grape-swagger.rb**

Add to `lib/grape-swagger.rb` after other requires:
```ruby
require 'grape-swagger/components_registry'
```

**Step 5: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/components_registry_spec.rb -v`
Expected: PASS (4 examples, 0 failures)

**Step 6: Commit**

```bash
git add lib/grape-swagger/components_registry.rb spec/grape-swagger/components_registry_spec.rb lib/grape-swagger.rb
git commit -m "feat: add ComponentsRegistry for reusable components"
```

---

## Task 2: Registry to_openapi and Collision Warnings

**Files:**
- Modify: `lib/grape-swagger/components_registry.rb`
- Modify: `spec/grape-swagger/components_registry_spec.rb`

**Step 1: Write the failing test for to_openapi**

Add to `spec/grape-swagger/components_registry_spec.rb`:

```ruby
describe '.to_openapi' do
  it 'builds components hash from registered classes' do
    param_class = Class.new do
      def self.name
        'PageParam'
      end

      def self.component_name
        nil
      end

      def self.to_openapi
        { name: 'page', in: 'query', schema: { type: 'integer' } }
      end
    end

    response_class = Class.new do
      def self.name
        'NotFoundResponse'
      end

      def self.component_name
        nil
      end

      def self.to_openapi
        { description: 'Resource not found' }
      end
    end

    described_class.register_parameter(param_class)
    described_class.register_response(response_class)

    result = described_class.to_openapi

    expect(result[:parameters]).to have_key('PageParam')
    expect(result[:parameters]['PageParam'][:name]).to eq('page')
    expect(result[:responses]).to have_key('NotFoundResponse')
    expect(result[:responses]['NotFoundResponse'][:description]).to eq('Resource not found')
  end

  it 'returns empty hash sections when no components registered' do
    result = described_class.to_openapi

    expect(result).to eq({})
  end
end

describe '.find_parameter!' do
  it 'returns the registered parameter class' do
    mock_class = Class.new do
      def self.name
        'PageParam'
      end

      def self.component_name
        nil
      end
    end

    described_class.register_parameter(mock_class)

    expect(described_class.find_parameter!('PageParam')).to eq(mock_class)
  end

  it 'raises ComponentNotFoundError for missing parameter' do
    expect { described_class.find_parameter!('NonExistent') }
      .to raise_error(GrapeSwagger::ComponentNotFoundError, /not found/)
  end
end

describe 'collision warnings' do
  it 'warns when registering duplicate component name' do
    class1 = Class.new do
      def self.name
        'Api::V1::PageParam'
      end

      def self.component_name
        nil
      end
    end

    class2 = Class.new do
      def self.name
        'Api::V2::PageParam'
      end

      def self.component_name
        nil
      end
    end

    described_class.register_parameter(class1)

    expect { described_class.register_parameter(class2) }
      .to output(/collision.*PageParam/i).to_stderr
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/components_registry_spec.rb -v`
Expected: FAIL with undefined method `to_openapi` or `find_parameter!`

**Step 3: Update implementation**

```ruby
# lib/grape-swagger/components_registry.rb
# frozen_string_literal: true

module GrapeSwagger
  class ComponentNotFoundError < StandardError; end

  class ComponentsRegistry
    class << self
      def parameters
        @parameters ||= {}
      end

      def responses
        @responses ||= {}
      end

      def headers
        @headers ||= {}
      end

      def register_parameter(klass)
        name = component_name_for(klass)
        warn_collision(:parameters, name, klass)
        parameters[name] = klass
      end

      def register_response(klass)
        name = component_name_for(klass)
        warn_collision(:responses, name, klass)
        responses[name] = klass
      end

      def register_header(klass)
        name = component_name_for(klass)
        warn_collision(:headers, name, klass)
        headers[name] = klass
      end

      def find_parameter!(name)
        parameters[name.to_s] || raise(
          ComponentNotFoundError,
          "Parameter component '#{name}' not found. Available: #{parameters.keys.join(', ')}"
        )
      end

      def find_response!(name)
        responses[name.to_s] || raise(
          ComponentNotFoundError,
          "Response component '#{name}' not found. Available: #{responses.keys.join(', ')}"
        )
      end

      def find_header!(name)
        headers[name.to_s] || raise(
          ComponentNotFoundError,
          "Header component '#{name}' not found. Available: #{headers.keys.join(', ')}"
        )
      end

      def component_name_for(klass)
        klass.component_name || klass.name.split('::').last
      end

      def to_openapi
        result = {}

        unless parameters.empty?
          result[:parameters] = parameters.transform_values(&:to_openapi)
        end

        unless responses.empty?
          result[:responses] = responses.transform_values(&:to_openapi)
        end

        unless headers.empty?
          result[:headers] = headers.transform_values(&:to_openapi)
        end

        result
      end

      def reset!
        @parameters = {}
        @responses = {}
        @headers = {}
      end

      private

      def warn_collision(type, name, klass)
        registry = send(type)
        return unless registry[name] && registry[name] != klass

        warn "[grape-swagger] Component name collision: #{name} already registered " \
             "by #{registry[name].name}, now being overwritten by #{klass.name}. " \
             "Use `component_name 'UniqueNameHere'` to resolve."
      end
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/components_registry_spec.rb -v`
Expected: PASS (8 examples, 0 failures)

**Step 5: Commit**

```bash
git add lib/grape-swagger/components_registry.rb spec/grape-swagger/components_registry_spec.rb
git commit -m "feat: add to_openapi, find methods, and collision warnings to registry"
```

---

## Task 3: ReusableParameter Base Class

**Files:**
- Create: `lib/grape-swagger/reusable_parameter.rb`
- Test: `spec/grape-swagger/reusable_parameter_spec.rb`

**Step 1: Write the failing test**

```ruby
# spec/grape-swagger/reusable_parameter_spec.rb
# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::ReusableParameter do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  describe 'DSL' do
    it 'defines a parameter with all fields' do
      param_class = Class.new(described_class) do
        def self.name
          'TestPageParam'
        end

        name 'page'
        in_query
        schema type: 'integer', default: 1, minimum: 1
        description 'Page number for pagination'
        required false
        deprecated false
        example 1
      end

      openapi = param_class.to_openapi

      expect(openapi[:name]).to eq('page')
      expect(openapi[:in]).to eq('query')
      expect(openapi[:schema]).to eq(type: 'integer', default: 1, minimum: 1)
      expect(openapi[:description]).to eq('Page number for pagination')
      expect(openapi[:required]).to eq(false)
      expect(openapi[:deprecated]).to eq(false)
      expect(openapi[:example]).to eq(1)
    end

    it 'supports in_path location' do
      param_class = Class.new(described_class) do
        def self.name
          'TestIdParam'
        end

        name 'id'
        in_path
        schema type: 'integer'
        required true
      end

      expect(param_class.to_openapi[:in]).to eq('path')
    end

    it 'supports in_header location' do
      param_class = Class.new(described_class) do
        def self.name
          'TestHeaderParam'
        end

        name 'X-Request-ID'
        in_header
        schema type: 'string'
      end

      expect(param_class.to_openapi[:in]).to eq('header')
    end

    it 'supports in_cookie location' do
      param_class = Class.new(described_class) do
        def self.name
          'TestCookieParam'
        end

        name 'session_id'
        in_cookie
        schema type: 'string'
      end

      expect(param_class.to_openapi[:in]).to eq('cookie')
    end

    it 'excludes nil values from output' do
      param_class = Class.new(described_class) do
        def self.name
          'MinimalParam'
        end

        name 'simple'
        in_query
        schema type: 'string'
      end

      openapi = param_class.to_openapi

      expect(openapi).not_to have_key(:description)
      expect(openapi).not_to have_key(:required)
      expect(openapi).not_to have_key(:deprecated)
      expect(openapi).not_to have_key(:example)
    end

    it 'supports custom component_name' do
      param_class = Class.new(described_class) do
        def self.name
          'Api::V2::PageParam'
        end

        component_name 'V2PageParam'
        name 'page'
        in_query
        schema type: 'integer'
      end

      expect(param_class.component_name).to eq('V2PageParam')
    end
  end

  describe 'auto-registration' do
    it 'auto-registers when subclass is defined' do
      # Define a new class - should auto-register
      test_class = Class.new(described_class) do
        def self.name
          'AutoRegisteredParam'
        end

        name 'auto'
        in_query
        schema type: 'string'
      end

      expect(GrapeSwagger::ComponentsRegistry.parameters).to have_key('AutoRegisteredParam')
      expect(GrapeSwagger::ComponentsRegistry.parameters['AutoRegisteredParam']).to eq(test_class)
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/reusable_parameter_spec.rb -v`
Expected: FAIL with "uninitialized constant GrapeSwagger::ReusableParameter"

**Step 3: Write implementation**

```ruby
# lib/grape-swagger/reusable_parameter.rb
# frozen_string_literal: true

module GrapeSwagger
  class ReusableParameter
    class << self
      attr_accessor :component_name

      def inherited(subclass)
        super
        # Defer registration to allow DSL to execute
        TracePoint.new(:end) do |tp|
          if tp.self == subclass
            GrapeSwagger::ComponentsRegistry.register_parameter(subclass)
            tp.disable
          end
        end.enable
      end

      # DSL Methods
      def name(val = nil)
        return @param_name if val.nil?

        @param_name = val
      end

      def in_location(val)
        @in = val
      end

      def in_query
        in_location('query')
      end

      def in_path
        in_location('path')
      end

      def in_header
        in_location('header')
      end

      def in_cookie
        in_location('cookie')
      end

      def schema(opts)
        @schema = opts
      end

      def description(val)
        @description = val
      end

      def required(val)
        @required = val
      end

      def deprecated(val)
        @deprecated = val
      end

      def example(val)
        @example = val
      end

      def to_openapi
        {
          name: @param_name,
          in: @in,
          schema: @schema,
          description: @description,
          required: @required,
          deprecated: @deprecated,
          example: @example
        }.compact
      end
    end
  end
end
```

**Step 4: Add require to grape-swagger.rb**

Add to `lib/grape-swagger.rb` after components_registry require:
```ruby
require 'grape-swagger/reusable_parameter'
```

**Step 5: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/reusable_parameter_spec.rb -v`
Expected: PASS (7 examples, 0 failures)

**Step 6: Commit**

```bash
git add lib/grape-swagger/reusable_parameter.rb spec/grape-swagger/reusable_parameter_spec.rb lib/grape-swagger.rb
git commit -m "feat: add ReusableParameter base class with DSL"
```

---

## Task 4: ReusableResponse Base Class

**Files:**
- Create: `lib/grape-swagger/reusable_response.rb`
- Test: `spec/grape-swagger/reusable_response_spec.rb`

**Step 1: Write the failing test**

```ruby
# spec/grape-swagger/reusable_response_spec.rb
# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::ReusableResponse do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  describe 'DSL' do
    it 'defines a response with description and content' do
      response_class = Class.new(described_class) do
        def self.name
          'TestNotFoundResponse'
        end

        description 'Resource not found'
        content 'application/json', schema: { type: 'object', properties: { error: { type: 'string' } } }
      end

      openapi = response_class.to_openapi

      expect(openapi[:description]).to eq('Resource not found')
      expect(openapi[:content]).to have_key('application/json')
      expect(openapi[:content]['application/json'][:schema][:type]).to eq('object')
    end

    it 'supports json_schema shorthand' do
      # Mock entity class
      mock_entity = Class.new do
        def self.name
          'ErrorEntity'
        end
      end

      response_class = Class.new(described_class) do
        def self.name
          'TestErrorResponse'
        end

        description 'An error occurred'
        json_schema mock_entity
      end

      openapi = response_class.to_openapi

      expect(openapi[:content]).to have_key('application/json')
      expect(openapi[:content]['application/json'][:schema]).to eq(mock_entity)
    end

    it 'supports multiple content types' do
      response_class = Class.new(described_class) do
        def self.name
          'TestMultiResponse'
        end

        description 'Multi-format response'
        content 'application/json', schema: { type: 'object' }
        content 'application/xml', schema: { type: 'object' }
      end

      openapi = response_class.to_openapi

      expect(openapi[:content].keys).to contain_exactly('application/json', 'application/xml')
    end

    it 'excludes nil values from output' do
      response_class = Class.new(described_class) do
        def self.name
          'MinimalResponse'
        end

        description 'Simple response'
      end

      openapi = response_class.to_openapi

      expect(openapi).to have_key(:description)
      expect(openapi).not_to have_key(:content)
      expect(openapi).not_to have_key(:headers)
    end

    it 'supports custom component_name' do
      response_class = Class.new(described_class) do
        def self.name
          'Api::V2::NotFoundResponse'
        end

        component_name 'V2NotFound'
        description 'Not found'
      end

      expect(response_class.component_name).to eq('V2NotFound')
    end
  end

  describe 'auto-registration' do
    it 'auto-registers when subclass is defined' do
      test_class = Class.new(described_class) do
        def self.name
          'AutoRegisteredResponse'
        end

        description 'Auto registered'
      end

      expect(GrapeSwagger::ComponentsRegistry.responses).to have_key('AutoRegisteredResponse')
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/reusable_response_spec.rb -v`
Expected: FAIL with "uninitialized constant GrapeSwagger::ReusableResponse"

**Step 3: Write implementation**

```ruby
# lib/grape-swagger/reusable_response.rb
# frozen_string_literal: true

module GrapeSwagger
  class ReusableResponse
    class << self
      attr_accessor :component_name

      def inherited(subclass)
        super
        TracePoint.new(:end) do |tp|
          if tp.self == subclass
            GrapeSwagger::ComponentsRegistry.register_response(subclass)
            tp.disable
          end
        end.enable
      end

      # DSL Methods
      def description(val)
        @description = val
      end

      def content(media_type, opts = {})
        @content ||= {}
        @content[media_type] = opts
      end

      def json_schema(entity_or_schema)
        content 'application/json', schema: entity_or_schema
      end

      def headers(&block)
        @headers_block = block
      end

      def to_openapi
        result = { description: @description }
        result[:content] = @content if @content && !@content.empty?
        result[:headers] = build_headers if @headers_block
        result.compact
      end

      private

      def build_headers
        # Future: evaluate headers block
        nil
      end
    end
  end
end
```

**Step 4: Add require to grape-swagger.rb**

Add to `lib/grape-swagger.rb`:
```ruby
require 'grape-swagger/reusable_response'
```

**Step 5: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/reusable_response_spec.rb -v`
Expected: PASS (6 examples, 0 failures)

**Step 6: Commit**

```bash
git add lib/grape-swagger/reusable_response.rb spec/grape-swagger/reusable_response_spec.rb lib/grape-swagger.rb
git commit -m "feat: add ReusableResponse base class with DSL"
```

---

## Task 5: ReusableHeader Base Class

**Files:**
- Create: `lib/grape-swagger/reusable_header.rb`
- Test: `spec/grape-swagger/reusable_header_spec.rb`

**Step 1: Write the failing test**

```ruby
# spec/grape-swagger/reusable_header_spec.rb
# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::ReusableHeader do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  describe 'DSL' do
    it 'defines a header with all fields' do
      header_class = Class.new(described_class) do
        def self.name
          'TestRateLimitHeader'
        end

        description 'Number of requests remaining'
        schema type: 'integer'
        required false
        deprecated false
        example 99
      end

      openapi = header_class.to_openapi

      expect(openapi[:description]).to eq('Number of requests remaining')
      expect(openapi[:schema]).to eq(type: 'integer')
      expect(openapi[:required]).to eq(false)
      expect(openapi[:deprecated]).to eq(false)
      expect(openapi[:example]).to eq(99)
    end

    it 'excludes nil values from output' do
      header_class = Class.new(described_class) do
        def self.name
          'MinimalHeader'
        end

        description 'Simple header'
        schema type: 'string'
      end

      openapi = header_class.to_openapi

      expect(openapi).to have_key(:description)
      expect(openapi).to have_key(:schema)
      expect(openapi).not_to have_key(:required)
      expect(openapi).not_to have_key(:deprecated)
      expect(openapi).not_to have_key(:example)
    end

    it 'supports custom component_name' do
      header_class = Class.new(described_class) do
        def self.name
          'Api::V2::RateLimitHeader'
        end

        component_name 'V2RateLimit'
        description 'Rate limit'
        schema type: 'integer'
      end

      expect(header_class.component_name).to eq('V2RateLimit')
    end
  end

  describe 'auto-registration' do
    it 'auto-registers when subclass is defined' do
      test_class = Class.new(described_class) do
        def self.name
          'AutoRegisteredHeader'
        end

        description 'Auto registered'
        schema type: 'string'
      end

      expect(GrapeSwagger::ComponentsRegistry.headers).to have_key('AutoRegisteredHeader')
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/reusable_header_spec.rb -v`
Expected: FAIL with "uninitialized constant GrapeSwagger::ReusableHeader"

**Step 3: Write implementation**

```ruby
# lib/grape-swagger/reusable_header.rb
# frozen_string_literal: true

module GrapeSwagger
  class ReusableHeader
    class << self
      attr_accessor :component_name

      def inherited(subclass)
        super
        TracePoint.new(:end) do |tp|
          if tp.self == subclass
            GrapeSwagger::ComponentsRegistry.register_header(subclass)
            tp.disable
          end
        end.enable
      end

      # DSL Methods
      def description(val)
        @description = val
      end

      def schema(opts)
        @schema = opts
      end

      def required(val)
        @required = val
      end

      def deprecated(val)
        @deprecated = val
      end

      def example(val)
        @example = val
      end

      def to_openapi
        {
          description: @description,
          schema: @schema,
          required: @required,
          deprecated: @deprecated,
          example: @example
        }.compact
      end
    end
  end
end
```

**Step 4: Add require to grape-swagger.rb**

Add to `lib/grape-swagger.rb`:
```ruby
require 'grape-swagger/reusable_header'
```

**Step 5: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/reusable_header_spec.rb -v`
Expected: PASS (4 examples, 0 failures)

**Step 6: Commit**

```bash
git add lib/grape-swagger/reusable_header.rb spec/grape-swagger/reusable_header_spec.rb lib/grape-swagger.rb
git commit -m "feat: add ReusableHeader base class with DSL"
```

---

## Task 6: Integrate Registry with ComponentsBuilder

**Files:**
- Modify: `lib/grape-swagger/openapi/components_builder.rb`
- Modify: `spec/grape-swagger/openapi/components_builder_spec.rb`

**Step 1: Write the failing test**

Add to `spec/grape-swagger/openapi/components_builder_spec.rb`:

```ruby
context 'with auto-registered reusable components' do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  it 'merges auto-registered parameters into components' do
    # Create and register a parameter
    param_class = Class.new(GrapeSwagger::ReusableParameter) do
      def self.name
        'BuilderTestPageParam'
      end

      name 'page'
      in_query
      schema type: 'integer', default: 1
      description 'Page number'
    end

    components = described_class.build({})

    expect(components[:parameters]).to have_key('BuilderTestPageParam')
    expect(components[:parameters]['BuilderTestPageParam'][:name]).to eq('page')
  end

  it 'merges auto-registered responses into components' do
    response_class = Class.new(GrapeSwagger::ReusableResponse) do
      def self.name
        'BuilderTestNotFound'
      end

      description 'Not found'
      json_schema({ type: 'object' })
    end

    components = described_class.build({})

    expect(components[:responses]).to have_key('BuilderTestNotFound')
    expect(components[:responses]['BuilderTestNotFound'][:description]).to eq('Not found')
  end

  it 'merges auto-registered headers into components' do
    header_class = Class.new(GrapeSwagger::ReusableHeader) do
      def self.name
        'BuilderTestRateLimit'
      end

      description 'Rate limit remaining'
      schema type: 'integer'
    end

    components = described_class.build({})

    expect(components[:headers]).to have_key('BuilderTestRateLimit')
  end

  it 'manual components take precedence over auto-registered' do
    # Auto-register
    Class.new(GrapeSwagger::ReusableParameter) do
      def self.name
        'PrecedenceTestParam'
      end

      name 'page'
      in_query
      schema type: 'integer'
      description 'Auto description'
    end

    # Manual override
    options = {
      components: {
        parameters: {
          'PrecedenceTestParam' => {
            name: 'page',
            in: 'query',
            schema: { type: 'integer' },
            description: 'Manual description'
          }
        }
      }
    }

    components = described_class.build(options)

    expect(components[:parameters]['PrecedenceTestParam'][:description]).to eq('Manual description')
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/openapi/components_builder_spec.rb -v --example "auto-registered"`
Expected: FAIL - auto-registered components not appearing

**Step 3: Update ComponentsBuilder**

Modify `lib/grape-swagger/openapi/components_builder.rb`:

```ruby
# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class ComponentsBuilder
      COMPONENT_KEYS = %i[
        schemas
        responses
        parameters
        examples
        requestBodies
        headers
        securitySchemes
        links
        callbacks
      ].freeze

      def self.build(options)
        components = {}
        version = options[:version]

        # Start with auto-registered reusable components
        registered = GrapeSwagger::ComponentsRegistry.to_openapi
        registered.each do |key, value|
          components[key] = value.dup if value && !value.empty?
        end

        # Merge explicit components (takes precedence)
        if options[:components]
          options[:components].each do |key, value|
            if components[key]
              components[key] = components[key].merge(value)
            else
              components[key] = value.dup
            end
          end
        end

        # Handle legacy definitions -> schemas
        if options[:definitions] && !components[:schemas]
          components[:schemas] = options[:definitions].dup
        end

        # Handle legacy securityDefinitions -> securitySchemes
        if options[:securityDefinitions] && !components[:securitySchemes]
          components[:securitySchemes] = options[:securityDefinitions].dup
        end

        # Transform security schemes if version is provided
        if version && components[:securitySchemes]
          components[:securitySchemes] = transform_security_schemes(components[:securitySchemes], version)
        end

        # Translate references if version is provided and it's OpenAPI 3.x
        components = translate_component_references(components, version) if version && !version.swagger_2_0?

        # Only include keys that have values
        components.select { |_key, value| value && !value.empty? }
      end

      # ... rest of existing methods unchanged ...
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/openapi/components_builder_spec.rb -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/grape-swagger/openapi/components_builder.rb spec/grape-swagger/openapi/components_builder_spec.rb
git commit -m "feat: integrate ComponentsRegistry with ComponentsBuilder"
```

---

## Task 7: Parameter Reference DSL (ref method)

**Files:**
- Create: `lib/grape-swagger/endpoint/params_extensions.rb`
- Test: `spec/grape-swagger/endpoint/params_extensions_spec.rb`
- Modify: `lib/grape-swagger.rb`

**Step 1: Write the failing test**

```ruby
# spec/grape-swagger/endpoint/params_extensions_spec.rb
# frozen_string_literal: true

require 'spec_helper'

describe 'Parameter reference DSL' do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  let(:app) do
    # Define reusable parameter
    Class.new(GrapeSwagger::ReusableParameter) do
      def self.name
        'RefTestPageParam'
      end

      name 'page'
      in_query
      schema type: 'integer', default: 1
      description 'Page number'
    end

    Class.new(Grape::API) do
      format :json

      desc 'List items'
      params do
        ref :RefTestPageParam
        optional :filter, type: String, desc: 'Filter string'
      end
      get '/items' do
        { page: params[:page], filter: params[:filter] }
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it 'generates $ref for referenced parameter' do
    parameters = subject['paths']['/items']['get']['parameters']

    ref_param = parameters.find { |p| p['$ref'] }
    expect(ref_param).not_to be_nil
    expect(ref_param['$ref']).to eq('#/components/parameters/RefTestPageParam')
  end

  it 'still includes inline parameters' do
    parameters = subject['paths']['/items']['get']['parameters']

    filter_param = parameters.find { |p| p['name'] == 'filter' }
    expect(filter_param).not_to be_nil
    expect(filter_param['in']).to eq('query')
  end

  it 'includes referenced parameter in components' do
    expect(subject['components']['parameters']).to have_key('RefTestPageParam')
    expect(subject['components']['parameters']['RefTestPageParam']['name']).to eq('page')
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/endpoint/params_extensions_spec.rb -v`
Expected: FAIL - `ref` method not defined

**Step 3: Write implementation**

This requires extending Grape's params DSL. The implementation approach:

```ruby
# lib/grape-swagger/endpoint/params_extensions.rb
# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    module ParamsExtensions
      def ref(component_name)
        # Store reference for OpenAPI doc generation
        @api.route_setting(:parameter_refs) do |refs|
          refs ||= []
          refs << component_name.to_s
          refs
        end

        # Also apply the actual Grape parameter for runtime validation
        klass = GrapeSwagger::ComponentsRegistry.find_parameter!(component_name)
        openapi = klass.to_openapi

        # Convert OpenAPI schema to Grape param options
        grape_type = openapi_type_to_grape(openapi.dig(:schema, :type))
        grape_opts = {
          type: grape_type,
          desc: openapi[:description],
          default: openapi.dig(:schema, :default)
        }.compact

        if openapi[:required]
          requires openapi[:name].to_sym, grape_opts
        else
          optional openapi[:name].to_sym, grape_opts
        end
      end

      private

      def openapi_type_to_grape(type)
        case type.to_s
        when 'integer' then Integer
        when 'number' then Float
        when 'boolean' then Grape::API::Boolean
        when 'array' then Array
        else String
        end
      end
    end
  end
end

# Patch into Grape's params DSL
Grape::Validations::ParamsScope.include(GrapeSwagger::Endpoint::ParamsExtensions)
```

**Step 4: Modify endpoint.rb to read refs and generate $ref**

In `lib/grape-swagger/endpoint.rb`, find the method that builds parameters and add:

```ruby
# Add near the parameter building logic
def path_item_object(...)
  # ... existing code ...

  # Check for parameter refs
  if route.settings[:parameter_refs]
    route.settings[:parameter_refs].each do |ref_name|
      parameters << { '$ref' => "#/components/parameters/#{ref_name}" }
    end
  end

  # ... rest of existing parameter building ...
end
```

**Step 5: Add require to grape-swagger.rb**

```ruby
require 'grape-swagger/endpoint/params_extensions'
```

**Step 6: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/endpoint/params_extensions_spec.rb -v`
Expected: PASS (3 examples, 0 failures)

**Step 7: Commit**

```bash
git add lib/grape-swagger/endpoint/params_extensions.rb spec/grape-swagger/endpoint/params_extensions_spec.rb lib/grape-swagger.rb lib/grape-swagger/endpoint.rb
git commit -m "feat: add ref DSL method for parameter references"
```

---

## Task 8: Response Reference Support

**Files:**
- Modify: `lib/grape-swagger/endpoint.rb`
- Test: `spec/grape-swagger/endpoint/response_refs_spec.rb`

**Step 1: Write the failing test**

```ruby
# spec/grape-swagger/endpoint/response_refs_spec.rb
# frozen_string_literal: true

require 'spec_helper'

describe 'Response reference support' do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  let(:app) do
    # Define reusable response
    Class.new(GrapeSwagger::ReusableResponse) do
      def self.name
        'RefTestNotFound'
      end

      description 'Resource not found'
      json_schema({ type: 'object', properties: { error: { type: 'string' } } })
    end

    Class.new(GrapeSwagger::ReusableResponse) do
      def self.name
        'RefTestUnauthorized'
      end

      description 'Authentication required'
      json_schema({ type: 'object', properties: { message: { type: 'string' } } })
    end

    Class.new(Grape::API) do
      format :json

      desc 'Get item',
           success: { code: 200, message: 'Success' },
           failure: [
             { code: 404, model: :RefTestNotFound },
             { code: 401, model: :RefTestUnauthorized }
           ]
      get '/items/:id' do
        { id: params[:id] }
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it 'generates $ref for symbol model references' do
    responses = subject['paths']['/items/{id}']['get']['responses']

    expect(responses['404']).to eq({ '$ref' => '#/components/responses/RefTestNotFound' })
    expect(responses['401']).to eq({ '$ref' => '#/components/responses/RefTestUnauthorized' })
  end

  it 'includes referenced responses in components' do
    expect(subject['components']['responses']).to have_key('RefTestNotFound')
    expect(subject['components']['responses']['RefTestNotFound']['description']).to eq('Resource not found')
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/grape-swagger/endpoint/response_refs_spec.rb -v`
Expected: FAIL - Symbol models not generating $ref

**Step 3: Modify response generation in endpoint.rb**

Find the response building logic and handle Symbol models:

```ruby
# In the response building section of endpoint.rb
def build_response(code, response_spec, ...)
  model = response_spec[:model]

  # If model is a Symbol, it's a reference to a reusable response
  if model.is_a?(Symbol)
    # Verify it exists
    GrapeSwagger::ComponentsRegistry.find_response!(model)
    return { '$ref' => "#/components/responses/#{model}" }
  end

  # ... existing logic for class/entity models ...
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/grape-swagger/endpoint/response_refs_spec.rb -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/grape-swagger/endpoint.rb spec/grape-swagger/endpoint/response_refs_spec.rb
git commit -m "feat: add response reference support with Symbol models"
```

---

## Task 9: End-to-End Integration Test

**Files:**
- Create: `spec/integration/reusable_components_spec.rb`

**Step 1: Write comprehensive integration test**

```ruby
# spec/integration/reusable_components_spec.rb
# frozen_string_literal: true

require 'spec_helper'

describe 'Reusable Components Integration' do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  # Define reusable components
  before(:all) do
    # Parameters
    Object.const_set(:IntegrationPageParam, Class.new(GrapeSwagger::ReusableParameter) do
      def self.name
        'IntegrationPageParam'
      end

      name 'page'
      in_query
      schema type: 'integer', default: 1, minimum: 1
      description 'Page number for pagination'
    end)

    Object.const_set(:IntegrationPerPageParam, Class.new(GrapeSwagger::ReusableParameter) do
      def self.name
        'IntegrationPerPageParam'
      end

      name 'per_page'
      in_query
      schema type: 'integer', default: 20, minimum: 1, maximum: 100
      description 'Items per page'
    end)

    # Responses
    Object.const_set(:IntegrationNotFoundResponse, Class.new(GrapeSwagger::ReusableResponse) do
      def self.name
        'IntegrationNotFoundResponse'
      end

      description 'The requested resource was not found'
      json_schema({ type: 'object', properties: { error: { type: 'string' }, code: { type: 'integer' } } })
    end)

    Object.const_set(:IntegrationUnauthorizedResponse, Class.new(GrapeSwagger::ReusableResponse) do
      def self.name
        'IntegrationUnauthorizedResponse'
      end

      description 'Authentication is required'
      json_schema({ type: 'object', properties: { message: { type: 'string' } } })
    end)

    # Headers
    Object.const_set(:IntegrationRateLimitHeader, Class.new(GrapeSwagger::ReusableHeader) do
      def self.name
        'IntegrationRateLimitHeader'
      end

      description 'Number of API requests remaining in current window'
      schema type: 'integer'
      example 99
    end)
  end

  let(:app) do
    Class.new(Grape::API) do
      format :json

      resource :users do
        desc 'List all users',
             success: { code: 200, message: 'Success' },
             failure: [
               { code: 401, model: :IntegrationUnauthorizedResponse }
             ]
        params do
          ref :IntegrationPageParam
          ref :IntegrationPerPageParam
          optional :status, type: String, values: %w[active inactive], desc: 'Filter by status'
        end
        get do
          { users: [], page: params[:page], per_page: params[:per_page] }
        end

        desc 'Get a specific user',
             success: { code: 200, message: 'Success' },
             failure: [
               { code: 404, model: :IntegrationNotFoundResponse },
               { code: 401, model: :IntegrationUnauthorizedResponse }
             ]
        params do
          requires :id, type: Integer, desc: 'User ID'
        end
        get ':id' do
          { id: params[:id] }
        end
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'components section' do
    it 'includes all registered parameters' do
      params = subject['components']['parameters']

      expect(params).to have_key('IntegrationPageParam')
      expect(params).to have_key('IntegrationPerPageParam')
      expect(params['IntegrationPageParam']['name']).to eq('page')
      expect(params['IntegrationPageParam']['in']).to eq('query')
      expect(params['IntegrationPageParam']['schema']['type']).to eq('integer')
    end

    it 'includes all registered responses' do
      responses = subject['components']['responses']

      expect(responses).to have_key('IntegrationNotFoundResponse')
      expect(responses).to have_key('IntegrationUnauthorizedResponse')
      expect(responses['IntegrationNotFoundResponse']['description']).to eq('The requested resource was not found')
    end

    it 'includes all registered headers' do
      headers = subject['components']['headers']

      expect(headers).to have_key('IntegrationRateLimitHeader')
      expect(headers['IntegrationRateLimitHeader']['schema']['type']).to eq('integer')
    end
  end

  describe 'parameter references' do
    it 'generates $ref for referenced parameters in list endpoint' do
      params = subject['paths']['/users']['get']['parameters']
      refs = params.select { |p| p['$ref'] }

      expect(refs.length).to eq(2)
      expect(refs.map { |r| r['$ref'] }).to include(
        '#/components/parameters/IntegrationPageParam',
        '#/components/parameters/IntegrationPerPageParam'
      )
    end

    it 'still includes inline parameters alongside refs' do
      params = subject['paths']['/users']['get']['parameters']
      status_param = params.find { |p| p['name'] == 'status' }

      expect(status_param).not_to be_nil
      expect(status_param['in']).to eq('query')
    end
  end

  describe 'response references' do
    it 'generates $ref for error responses' do
      responses = subject['paths']['/users/{id}']['get']['responses']

      expect(responses['404']).to eq({ '$ref' => '#/components/responses/IntegrationNotFoundResponse' })
      expect(responses['401']).to eq({ '$ref' => '#/components/responses/IntegrationUnauthorizedResponse' })
    end

    it 'reuses same response reference across endpoints' do
      list_responses = subject['paths']['/users']['get']['responses']
      get_responses = subject['paths']['/users/{id}']['get']['responses']

      expect(list_responses['401']).to eq(get_responses['401'])
    end
  end

  describe 'runtime behavior' do
    it 'applies default values from referenced parameters' do
      get '/users'
      response = JSON.parse(last_response.body)

      expect(response['page']).to eq(1)
      expect(response['per_page']).to eq(20)
    end

    it 'accepts custom values for referenced parameters' do
      get '/users', page: 5, per_page: 50
      response = JSON.parse(last_response.body)

      expect(response['page']).to eq(5)
      expect(response['per_page']).to eq(50)
    end
  end
end
```

**Step 2: Run test**

Run: `bundle exec rspec spec/integration/reusable_components_spec.rb -v`
Expected: PASS (all examples)

**Step 3: Commit**

```bash
git add spec/integration/reusable_components_spec.rb
git commit -m "test: add comprehensive integration tests for reusable components"
```

---

## Task 10: Update Documentation and TABLE.md

**Files:**
- Modify: `openapi_spec/TABLE.md`
- Modify: `openapi_spec/ComponentsObject.md`
- Create: `openapi_spec/ReusableComponents.md`

**Step 1: Update TABLE.md**

Update the Components Object section to reflect new auto-generation support:

```markdown
## 30. Components Object

| Field | Type | Required | Spec Tests | Demo App |
|-------|------|----------|------------|----------|
| `schemas` | Map[string, Schema Object] | No | ✅ | ✅ |
| `responses` | Map[string, Response Object] | No | ✅ | ✅ |
| `parameters` | Map[string, Parameter Object] | No | ✅ | ✅ |
| `examples` | Map[string, Example Object] | No | ✅ | ❌ |
| `requestBodies` | Map[string, Request Body Object] | No | ✅ | ❌ |
| `headers` | Map[string, Header Object] | No | ✅ | ✅ |
| `securitySchemes` | Map[string, Security Scheme Object] | No | ✅ | ✅ |
| `links` | Map[string, Link Object] | No | ✅ | ❌ |
| `callbacks` | Map[string, Callback Object] | No | ✅ | ❌ |
| `pathItems` | Map[string, Path Item Object] | No | ❌ | ❌ |
```

**Step 2: Update ComponentsObject.md**

Add section about auto-generation from ReusableParameter, ReusableResponse, ReusableHeader.

**Step 3: Create ReusableComponents.md**

Document the new DSL with examples.

**Step 4: Commit**

```bash
git add openapi_spec/
git commit -m "docs: update documentation for reusable components feature"
```

---

## Task 11: Run Full Test Suite

**Step 1: Run all tests**

```bash
bundle exec rspec
```

Expected: All tests pass (1300+ examples, 0 failures)

**Step 2: Run RuboCop**

```bash
bundle exec rubocop lib/grape-swagger/components_registry.rb lib/grape-swagger/reusable_*.rb
```

Expected: No offenses

**Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "chore: fix any linting issues"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Components Registry (basic) | `components_registry.rb` |
| 2 | Registry to_openapi + collisions | `components_registry.rb` |
| 3 | ReusableParameter base class | `reusable_parameter.rb` |
| 4 | ReusableResponse base class | `reusable_response.rb` |
| 5 | ReusableHeader base class | `reusable_header.rb` |
| 6 | Integrate with ComponentsBuilder | `components_builder.rb` |
| 7 | Parameter ref DSL | `params_extensions.rb`, `endpoint.rb` |
| 8 | Response ref support | `endpoint.rb` |
| 9 | Integration tests | `reusable_components_spec.rb` |
| 10 | Documentation updates | `TABLE.md`, `ComponentsObject.md` |
| 11 | Full test suite | - |

**Estimated commits:** 11
**New files:** 7
**Modified files:** 5
