# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::ReusableExample do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  describe 'DSL' do
    it 'defines an example with all fields' do
      example_class = Class.new(described_class) do
        def self.name
          'PetDogExample'
        end

        summary 'Example dog'
        description 'A golden retriever named Buddy'
        value({
          id: 1,
          name: 'Buddy',
          pet_type: 'dog'
        })
      end

      openapi = example_class.to_openapi

      expect(openapi[:summary]).to eq('Example dog')
      expect(openapi[:description]).to eq('A golden retriever named Buddy')
      expect(openapi[:value]).to eq({ id: 1, name: 'Buddy', pet_type: 'dog' })
    end

    it 'supports external_value for external examples' do
      example_class = Class.new(described_class) do
        def self.name
          'ExternalPetExample'
        end

        summary 'External pet example'
        external_value 'https://api.example.com/examples/pet.json'
      end

      openapi = example_class.to_openapi

      expect(openapi[:summary]).to eq('External pet example')
      expect(openapi[:externalValue]).to eq('https://api.example.com/examples/pet.json')
      expect(openapi).not_to have_key(:value)
    end

    it 'value and external_value are mutually exclusive (external_value wins if both set)' do
      example_class = Class.new(described_class) do
        def self.name
          'ConflictExample'
        end

        value({ inline: true })
        external_value 'https://example.com/data.json'
      end

      openapi = example_class.to_openapi

      expect(openapi[:externalValue]).to eq('https://example.com/data.json')
      expect(openapi).not_to have_key(:value)
    end
  end

  describe 'auto-registration' do
    it 'auto-registers when subclass is defined' do
      Class.new(described_class) do
        def self.name
          'AutoRegisteredExample'
        end

        summary 'Auto registered'
        value({ test: true })
      end

      expect(GrapeSwagger::ComponentsRegistry.examples).to have_key('AutoRegisteredExample')
    end
  end
end
