# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::DiscriminatorBuilder do
  describe '.build' do
    context 'discriminator with propertyName only' do
      it 'creates discriminator object with propertyName' do
        config = { property_name: 'petType' }

        result = described_class.build(config)

        expect(result).to be_a(Hash)
        expect(result[:propertyName]).to eq('petType')
        expect(result).not_to have_key(:mapping)
      end
    end

    context 'discriminator with explicit mapping' do
      it 'creates discriminator with mapping hash' do
        config = {
          property_name: 'petType',
          mapping: { 'dog' => 'Dog', 'cat' => 'Cat' }
        }

        result = described_class.build(config)

        expect(result[:propertyName]).to eq('petType')
        expect(result[:mapping].keys).to include('dog', 'cat')
      end

      it 'converts schema names to component refs' do
        config = {
          property_name: 'petType',
          mapping: { 'dog' => 'Dog', 'cat' => 'Cat' }
        }

        result = described_class.build(config)

        expect(result[:mapping]['dog']).to eq('#/components/schemas/Dog')
        expect(result[:mapping]['cat']).to eq('#/components/schemas/Cat')
      end
    end

    context 'mapping to local schema refs' do
      it 'preserves existing component refs' do
        config = {
          property_name: 'petType',
          mapping: {
            'dog' => '#/components/schemas/Dog',
            'cat' => '#/components/schemas/Cat'
          }
        }

        result = described_class.build(config)

        expect(result[:mapping]['dog']).to eq('#/components/schemas/Dog')
        expect(result[:mapping]['cat']).to eq('#/components/schemas/Cat')
      end
    end

    context 'mapping to external refs' do
      it 'preserves external references' do
        config = {
          property_name: 'petType',
          mapping: {
            'dog' => '#/components/schemas/Dog',
            'cat' => 'https://example.com/schemas/Cat'
          }
        }

        result = described_class.build(config)

        expect(result[:mapping]['dog']).to eq('#/components/schemas/Dog')
        expect(result[:mapping]['cat']).to eq('https://example.com/schemas/Cat')
      end
    end

    context 'nil and empty input' do
      it 'returns nil for nil config' do
        expect(described_class.build(nil)).to be_nil
      end

      it 'returns nil for empty hash' do
        expect(described_class.build({})).to be_nil
      end
    end

    context 'edge cases' do
      it 'handles mixed ref formats in mapping' do
        config = {
          property_name: 'type',
          mapping: {
            'simple' => 'SimpleSchema',
            'local' => '#/components/schemas/LocalSchema',
            'external' => 'https://api.example.com/schemas/External'
          }
        }

        result = described_class.build(config)

        expect(result[:mapping]['simple']).to eq('#/components/schemas/SimpleSchema')
        expect(result[:mapping]['local']).to eq('#/components/schemas/LocalSchema')
        expect(result[:mapping]['external']).to eq('https://api.example.com/schemas/External')
      end

      it 'handles empty mapping hash' do
        config = { property_name: 'type', mapping: {} }

        result = described_class.build(config)

        expect(result[:propertyName]).to eq('type')
        expect(result[:mapping]).to eq({})
      end

      it 'handles mapping with symbol keys' do
        config = {
          property_name: 'type',
          mapping: { dog: 'Dog', cat: 'Cat' }
        }

        result = described_class.build(config)

        expect(result[:mapping][:dog]).to eq('#/components/schemas/Dog')
        expect(result[:mapping][:cat]).to eq('#/components/schemas/Cat')
      end
    end
  end
end
