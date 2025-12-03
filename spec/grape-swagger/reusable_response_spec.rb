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
      Class.new(described_class) do
        def self.name
          'AutoRegisteredResponse'
        end

        description 'Auto registered'
      end

      expect(GrapeSwagger::ComponentsRegistry.responses).to have_key('AutoRegisteredResponse')
    end
  end
end
