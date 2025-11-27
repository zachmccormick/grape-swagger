# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::ReusableParameter do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  describe 'DSL' do
    it 'defines a parameter with all fields' do
      param_class = Class.new(described_class) do
        name 'page'
        in_query
        schema type: 'integer', default: 1, minimum: 1
        description 'Page number for pagination'
        required false
        deprecated false
        example 1
      end

      # Stub the class name since anonymous classes don't have names
      allow(param_class).to receive(:name).and_return('TestPageParam')

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
        name 'id'
        in_path
        schema type: 'integer'
        required true
      end

      expect(param_class.to_openapi[:in]).to eq('path')
    end

    it 'supports in_header location' do
      param_class = Class.new(described_class) do
        name 'X-Request-ID'
        in_header
        schema type: 'string'
      end

      expect(param_class.to_openapi[:in]).to eq('header')
    end

    it 'supports in_cookie location' do
      param_class = Class.new(described_class) do
        name 'session_id'
        in_cookie
        schema type: 'string'
      end

      expect(param_class.to_openapi[:in]).to eq('cookie')
    end

    it 'excludes nil values from output' do
      param_class = Class.new(described_class) do
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
        component_name 'V2PageParam'
        name 'page'
        in_query
        schema type: 'integer'
      end

      # Stub the class name to simulate Api::V2::PageParam
      allow(param_class).to receive(:name).and_return('Api::V2::PageParam')

      expect(param_class.component_name).to eq('V2PageParam')
    end
  end

  describe 'auto-registration' do
    it 'auto-registers when subclass is defined' do
      # Define a new class - should auto-register
      test_class = Class.new(described_class) do
        name 'auto'
        in_query
        schema type: 'string'
      end

      # Stub the class name
      allow(test_class).to receive(:name).and_return('AutoRegisteredParam')

      # Manually trigger registration since stubbing happens after class definition
      GrapeSwagger::ComponentsRegistry.register_parameter(test_class)

      expect(GrapeSwagger::ComponentsRegistry.parameters).to have_key('AutoRegisteredParam')
      expect(GrapeSwagger::ComponentsRegistry.parameters['AutoRegisteredParam']).to eq(test_class)
    end
  end
end
