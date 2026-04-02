# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::DiscriminatorTransformer do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.transform' do
    context 'when version is Swagger 2.0' do
      it 'returns schemas unchanged' do
        schemas = {
          Pet: {
            type: 'object',
            discriminator: 'pet_type',
            properties: { pet_type: { type: 'string' } }
          }
        }

        result = described_class.transform(schemas, version_2_0)

        expect(result[:Pet][:discriminator]).to eq('pet_type')
      end
    end

    context 'when schemas is nil' do
      it 'returns nil' do
        result = described_class.transform(nil, version_3_1_0)
        expect(result).to be_nil
      end
    end

    context 'when schemas is not a Hash' do
      it 'returns the input unchanged' do
        result = described_class.transform('not a hash', version_3_1_0)
        expect(result).to eq('not a hash')
      end
    end

    context 'basic discriminator transformation' do
      it 'transforms string discriminator to object format' do
        schemas = {
          Pet: {
            type: 'object',
            discriminator: 'pet_type',
            properties: {
              pet_type: { type: 'string' },
              name: { type: 'string' }
            }
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        expect(result[:Pet][:discriminator]).to be_a(Hash)
        expect(result[:Pet][:discriminator][:propertyName]).to eq('pet_type')
      end

      it 'transforms symbol discriminator to object format' do
        schemas = {
          Pet: {
            type: 'object',
            discriminator: :pet_type,
            properties: {
              pet_type: { type: 'string' }
            }
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        expect(result[:Pet][:discriminator]).to be_a(Hash)
        expect(result[:Pet][:discriminator][:propertyName]).to eq('pet_type')
      end
    end

    context 'with parent-child relationships (string keys)' do
      # NOTE: Parent-child mapping requires string keys for schemas
      # because the parent name extracted from $ref is a string
      let(:schemas) do
        {
          'Pet' => {
            'type' => 'object',
            'discriminator' => 'pet_type',
            'properties' => {
              'pet_type' => { 'type' => 'string' },
              'name' => { 'type' => 'string' }
            }
          },
          'Dog' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              {
                'type' => 'object',
                'properties' => {
                  'pet_type' => { 'type' => 'string', 'enum' => ['dog'] },
                  'breed' => { 'type' => 'string' }
                }
              }
            ]
          },
          'Cat' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              {
                'type' => 'object',
                'properties' => {
                  'pet_type' => { 'type' => 'string', 'enum' => ['cat'] },
                  'color' => { 'type' => 'string' }
                }
              }
            ]
          }
        }
      end

      it 'builds mapping from child schemas' do
        result = described_class.transform(schemas, version_3_1_0)

        expect(result['Pet']['discriminator'][:mapping]).to be_a(Hash)
        expect(result['Pet']['discriminator'][:mapping]['dog']).to eq('#/components/schemas/Dog')
      end

      it 'preserves propertyName' do
        result = described_class.transform(schemas, version_3_1_0)

        expect(result['Pet']['discriminator'][:propertyName]).to eq('pet_type')
      end
    end

    context 'with entity name pattern in enum' do
      let(:schemas) do
        {
          'Pet' => {
            'type' => 'object',
            'discriminator' => 'pet_type',
            'properties' => {
              'pet_type' => { 'type' => 'string' }
            }
          },
          'V1_Entities_Dog' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              {
                'type' => 'object',
                'properties' => {
                  'pet_type' => { 'type' => 'string', 'enum' => ['V1_Entities_Dog'] },
                  'breed' => { 'type' => 'string' }
                }
              }
            ]
          }
        }
      end

      it 'derives discriminator value from schema name' do
        result = described_class.transform(schemas, version_3_1_0)

        expect(result['Pet']['discriminator'][:mapping]).to have_key('dog')
        expect(result['Pet']['discriminator'][:mapping]['dog']).to eq('#/components/schemas/V1_Entities_Dog')
      end

      it 'fixes child enum with derived value' do
        result = described_class.transform(schemas, version_3_1_0)

        dog_schema = result['V1_Entities_Dog']
        extension = dog_schema['allOf'].find { |s| !s['$ref'] }
        expect(extension['properties']['pet_type']['enum']).to eq(['dog'])
      end
    end

    context 'with CamelCase schema names' do
      let(:schemas) do
        {
          'PaymentMethod' => {
            'type' => 'object',
            'discriminator' => 'type',
            'properties' => { 'type' => { 'type' => 'string' } }
          },
          'V1_Entities_CreditCard' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/PaymentMethod' },
              {
                'type' => 'object',
                'properties' => {
                  'type' => { 'type' => 'string', 'enum' => ['V1_Entities_CreditCard'] }
                }
              }
            ]
          }
        }
      end

      it 'converts CamelCase to snake_case for discriminator value' do
        result = described_class.transform(schemas, version_3_1_0)

        expect(result['PaymentMethod']['discriminator'][:mapping]).to have_key('credit_card')
      end
    end

    context 'with string keys in schemas' do
      let(:schemas) do
        {
          'Pet' => {
            'type' => 'object',
            'discriminator' => 'pet_type',
            'properties' => {
              'pet_type' => { 'type' => 'string' }
            }
          },
          'Dog' => {
            'allOf' => [
              { '$ref' => '#/definitions/Pet' },
              {
                'type' => 'object',
                'properties' => {
                  'pet_type' => { 'type' => 'string', 'enum' => ['dog'] }
                }
              }
            ]
          }
        }
      end

      it 'handles string keys correctly' do
        result = described_class.transform(schemas, version_3_1_0)

        expect(result['Pet']['discriminator']).to be_a(Hash)
        expect(result['Pet']['discriminator'][:propertyName]).to eq('pet_type')
      end
    end

    context 'with no children' do
      let(:schemas) do
        {
          Pet: {
            type: 'object',
            discriminator: 'pet_type',
            properties: { pet_type: { type: 'string' } }
          }
        }
      end

      it 'transforms discriminator without mapping' do
        result = described_class.transform(schemas, version_3_1_0)

        expect(result[:Pet][:discriminator][:propertyName]).to eq('pet_type')
        expect(result[:Pet][:discriminator]).not_to have_key(:mapping)
      end
    end

    context 'with schema that is not a Hash' do
      it 'skips non-hash schemas' do
        schemas = {
          Pet: 'not a hash',
          Dog: {
            type: 'object',
            discriminator: 'type'
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        expect(result[:Pet]).to eq('not a hash')
      end
    end

    context 'with allOf that is not an Array' do
      it 'skips schemas with non-array allOf' do
        schemas = {
          Pet: {
            type: 'object',
            discriminator: 'pet_type',
            properties: { pet_type: { type: 'string' } }
          },
          Dog: {
            allOf: 'not an array'
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        # Should not crash, Pet should still be transformed
        expect(result[:Pet][:discriminator][:propertyName]).to eq('pet_type')
      end
    end

    context 'with allOf without $ref' do
      it 'skips allOf entries without parent reference' do
        schemas = {
          Dog: {
            allOf: [
              { type: 'object', properties: { name: { type: 'string' } } }
            ]
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        expect(result[:Dog][:allOf]).to be_an(Array)
      end
    end

    context 'with invalid $ref' do
      it 'handles refs without #/' do
        schemas = {
          Pet: {
            type: 'object',
            discriminator: 'pet_type'
          },
          Dog: {
            allOf: [
              { :$ref => 'external.json' }
            ]
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        expect(result[:Pet][:discriminator][:propertyName]).to eq('pet_type')
      end
    end

    context 'with discriminator already in object format' do
      it 'skips already transformed discriminators' do
        schemas = {
          Pet: {
            type: 'object',
            discriminator: {
              propertyName: 'pet_type',
              mapping: { dog: '#/components/schemas/Dog' }
            }
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        # Should remain unchanged since discriminator is already an object
        expect(result[:Pet][:discriminator]).to be_a(Hash)
      end
    end

    context 'with properties that are not Hash' do
      it 'handles non-hash properties gracefully' do
        schemas = {
          Pet: {
            type: 'object',
            discriminator: 'pet_type'
          },
          Dog: {
            allOf: [
              { :$ref => '#/components/schemas/Pet' },
              { properties: 'not a hash' }
            ]
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        expect(result[:Pet][:discriminator][:propertyName]).to eq('pet_type')
      end
    end

    context 'with missing discriminator property in child' do
      it 'uses derived value when discriminator property not found in child' do
        schemas = {
          'Pet' => {
            'type' => 'object',
            'discriminator' => 'pet_type',
            'properties' => { 'pet_type' => { 'type' => 'string' } }
          },
          'Bird' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              {
                'type' => 'object',
                'properties' => {
                  'can_fly' => { 'type' => 'boolean' }
                }
              }
            ]
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        expect(result['Pet']['discriminator'][:mapping]).to have_key('bird')
      end
    end

    context 'fix_child_discriminator_enums' do
      it 'updates enum values when child has entity name pattern' do
        # When enum has an entity name pattern like V1_Entities_Dog,
        # it gets converted to derived value like 'dog'
        schemas = {
          'Pet' => {
            'type' => 'object',
            'discriminator' => 'pet_type',
            'properties' => { 'pet_type' => { 'type' => 'string' } }
          },
          'V1_Entities_Dog' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              {
                'type' => 'object',
                'properties' => {
                  'pet_type' => { 'type' => 'string', 'enum' => ['V1_Entities_Dog'] }
                }
              }
            ]
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        dog_ext = result['V1_Entities_Dog']['allOf'].find { |s| !s['$ref'] }
        expect(dog_ext['properties']['pet_type']['enum']).to eq(['dog'])
      end

      it 'preserves non-entity-pattern enum values' do
        # When enum has a regular value, it is used as-is for the discriminator
        schemas = {
          'Pet' => {
            'type' => 'object',
            'discriminator' => 'pet_type',
            'properties' => { 'pet_type' => { 'type' => 'string' } }
          },
          'Dog' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              {
                'type' => 'object',
                'properties' => {
                  'pet_type' => { 'enum' => ['custom_dog'] }
                }
              }
            ]
          }
        }

        result = described_class.transform(schemas, version_3_1_0)

        dog_ext = result['Dog']['allOf'].find { |s| !s['$ref'] }
        expect(dog_ext['properties']['pet_type']['enum']).to eq(['custom_dog'])
      end
    end

    context 'with multiple discriminator hierarchies' do
      let(:schemas) do
        {
          'Animal' => {
            'type' => 'object',
            'discriminator' => 'animal_type',
            'properties' => { 'animal_type' => { 'type' => 'string' } }
          },
          'Pet' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Animal' },
              {
                'type' => 'object',
                'discriminator' => 'pet_type',
                'properties' => {
                  'animal_type' => { 'type' => 'string', 'enum' => ['pet'] },
                  'pet_type' => { 'type' => 'string' }
                }
              }
            ]
          },
          'Dog' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              {
                'type' => 'object',
                'properties' => {
                  'pet_type' => { 'type' => 'string', 'enum' => ['dog'] }
                }
              }
            ]
          }
        }
      end

      it 'handles nested discriminator hierarchies' do
        result = described_class.transform(schemas, version_3_1_0)

        expect(result['Animal']['discriminator'][:mapping]).to have_key('pet')
      end
    end
  end
end
