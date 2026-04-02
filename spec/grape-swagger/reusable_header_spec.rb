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

    it 'supports deprecated true for deprecation warnings' do
      header_class = Class.new(described_class) do
        def self.name
          'DeprecatedHeader'
        end

        description 'This header is deprecated'
        schema type: 'string'
        deprecated true
      end

      openapi = header_class.to_openapi

      expect(openapi[:deprecated]).to eq(true)
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
