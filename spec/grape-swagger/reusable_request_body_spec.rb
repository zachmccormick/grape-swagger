# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::ReusableRequestBody do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  describe 'DSL' do
    it 'defines a request body with json_schema shorthand' do
      body_class = Class.new(described_class) do
        def self.name
          'CreatePetRequestBody'
        end

        description 'Payload for creating a new pet'
        required true
        json_schema({ type: 'object', properties: { name: { type: 'string' } } })
      end

      openapi = body_class.to_openapi

      expect(openapi[:description]).to eq('Payload for creating a new pet')
      expect(openapi[:required]).to eq(true)
      expect(openapi[:content]).to have_key('application/json')
      expect(openapi[:content]['application/json'][:schema]).to eq({
        type: 'object',
        properties: { name: { type: 'string' } }
      })
    end

    it 'defines a request body with explicit content types' do
      body_class = Class.new(described_class) do
        def self.name
          'MultiFormatBody'
        end

        description 'Multi-format request body'
        content 'application/json', schema: { type: 'object' }
        content 'application/xml', schema: { type: 'object' }
      end

      openapi = body_class.to_openapi

      expect(openapi[:content]).to have_key('application/json')
      expect(openapi[:content]).to have_key('application/xml')
    end
  end
end
