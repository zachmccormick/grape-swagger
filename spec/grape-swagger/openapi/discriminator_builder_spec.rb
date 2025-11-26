# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::DiscriminatorBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    # Story 14.1: Discriminator with Mapping
    context 'Story 14.1: Discriminator with Mapping' do
      context 'when discriminator with propertyName only' do
        it 'creates discriminator object with propertyName' do
          config = {
            property_name: 'petType'
          }

          result = described_class.build(config, version_3_1_0)

          expect(result).not_to be_nil
          expect(result).to be_a(Hash)
          expect(result[:propertyName]).to eq('petType')
          expect(result).not_to have_key(:mapping)
        end
      end

      context 'when discriminator with explicit mapping' do
        it 'creates discriminator with mapping hash' do
          config = {
            property_name: 'petType',
            mapping: {
              'dog' => 'Dog',
              'cat' => 'Cat'
            }
          }

          result = described_class.build(config, version_3_1_0)

          expect(result[:propertyName]).to eq('petType')
          expect(result[:mapping]).to be_a(Hash)
          expect(result[:mapping].keys).to include('dog', 'cat')
        end

        it 'converts schema names to component refs' do
          config = {
            property_name: 'petType',
            mapping: {
              'dog' => 'Dog',
              'cat' => 'Cat'
            }
          }

          result = described_class.build(config, version_3_1_0)

          expect(result[:mapping]['dog']).to eq('#/components/schemas/Dog')
          expect(result[:mapping]['cat']).to eq('#/components/schemas/Cat')
        end
      end

      context 'when mapping to local schema refs' do
        it 'preserves existing component refs' do
          config = {
            property_name: 'petType',
            mapping: {
              'dog' => '#/components/schemas/Dog',
              'cat' => '#/components/schemas/Cat'
            }
          }

          result = described_class.build(config, version_3_1_0)

          expect(result[:mapping]['dog']).to eq('#/components/schemas/Dog')
          expect(result[:mapping]['cat']).to eq('#/components/schemas/Cat')
        end
      end

      context 'when mapping to external refs' do
        it 'preserves external references' do
          config = {
            property_name: 'petType',
            mapping: {
              'dog' => '#/components/schemas/Dog',
              'cat' => 'https://example.com/schemas/Cat'
            }
          }

          result = described_class.build(config, version_3_1_0)

          expect(result[:mapping]['dog']).to eq('#/components/schemas/Dog')
          expect(result[:mapping]['cat']).to eq('https://example.com/schemas/Cat')
        end
      end

      context 'when used in Swagger 2.0' do
        it 'returns only propertyName as string' do
          config = {
            property_name: 'petType',
            mapping: {
              'dog' => 'Dog',
              'cat' => 'Cat'
            }
          }

          result = described_class.build(config, version_2_0)

          expect(result).to eq('petType')
        end

        it 'handles propertyName only in Swagger 2.0' do
          config = {
            property_name: 'type'
          }

          result = described_class.build(config, version_2_0)

          expect(result).to eq('type')
        end
      end

      context 'when discriminator is nil' do
        it 'returns nil' do
          result = described_class.build(nil, version_3_1_0)

          expect(result).to be_nil
        end
      end

      context 'when discriminator is empty hash' do
        it 'returns nil' do
          result = described_class.build({}, version_3_1_0)

          expect(result).to be_nil
        end
      end
    end

    # Edge cases
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

        result = described_class.build(config, version_3_1_0)

        expect(result[:mapping]['simple']).to eq('#/components/schemas/SimpleSchema')
        expect(result[:mapping]['local']).to eq('#/components/schemas/LocalSchema')
        expect(result[:mapping]['external']).to eq('https://api.example.com/schemas/External')
      end

      it 'handles empty mapping hash' do
        config = {
          property_name: 'type',
          mapping: {}
        }

        result = described_class.build(config, version_3_1_0)

        expect(result[:propertyName]).to eq('type')
        expect(result[:mapping]).to eq({})
      end

      it 'handles mapping with symbol keys' do
        config = {
          property_name: 'type',
          mapping: {
            dog: 'Dog',
            cat: 'Cat'
          }
        }

        result = described_class.build(config, version_3_1_0)

        expect(result[:mapping]).to have_key(:dog)
        expect(result[:mapping]).to have_key(:cat)
        expect(result[:mapping][:dog]).to eq('#/components/schemas/Dog')
      end
    end
  end
end
