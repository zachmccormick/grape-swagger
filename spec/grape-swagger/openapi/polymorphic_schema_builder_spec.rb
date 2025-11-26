# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build_one_of' do
    # Story 14.2: OneOf Schema Support
    context 'Story 14.2: OneOf Schema Support' do
      context 'when oneOf with two schemas' do
        it 'creates oneOf array with schema refs' do
          schemas = ['SuccessResponse', 'ErrorResponse']

          result = described_class.build_one_of(schemas, nil, version_3_1_0)

          expect(result).to be_a(Hash)
          expect(result[:oneOf]).to be_a(Array)
          expect(result[:oneOf].size).to eq(2)
        end

        it 'converts schema names to component refs' do
          schemas = ['SuccessResponse', 'ErrorResponse']

          result = described_class.build_one_of(schemas, nil, version_3_1_0)

          expect(result[:oneOf][0]).to eq({ '$ref' => '#/components/schemas/SuccessResponse' })
          expect(result[:oneOf][1]).to eq({ '$ref' => '#/components/schemas/ErrorResponse' })
        end
      end

      context 'when oneOf with multiple schemas' do
        it 'handles three or more schemas' do
          schemas = ['SchemaA', 'SchemaB', 'SchemaC', 'SchemaD']

          result = described_class.build_one_of(schemas, nil, version_3_1_0)

          expect(result[:oneOf].size).to eq(4)
          expect(result[:oneOf].map { |s| s['$ref'] }).to eq([
            '#/components/schemas/SchemaA',
            '#/components/schemas/SchemaB',
            '#/components/schemas/SchemaC',
            '#/components/schemas/SchemaD'
          ])
        end
      end

      context 'when oneOf with discriminator' do
        it 'includes discriminator object' do
          schemas = ['SuccessResponse', 'ErrorResponse']
          discriminator = {
            property_name: 'status',
            mapping: {
              'success' => 'SuccessResponse',
              'error' => 'ErrorResponse'
            }
          }

          result = described_class.build_one_of(schemas, discriminator, version_3_1_0)

          expect(result[:discriminator]).not_to be_nil
          expect(result[:discriminator][:propertyName]).to eq('status')
        end
      end

      context 'when inline schemas in oneOf' do
        it 'handles inline schema objects' do
          schemas = [
            { type: 'object', properties: { name: { type: 'string' } } },
            { type: 'object', properties: { id: { type: 'integer' } } }
          ]

          result = described_class.build_one_of(schemas, nil, version_3_1_0)

          expect(result[:oneOf][0]).to eq({ type: 'object', properties: { name: { type: 'string' } } })
          expect(result[:oneOf][1]).to eq({ type: 'object', properties: { id: { type: 'integer' } } })
        end
      end

      context 'when referenced schemas in oneOf' do
        it 'handles existing $ref objects' do
          schemas = [
            { '$ref' => '#/components/schemas/Dog' },
            { '$ref' => '#/components/schemas/Cat' }
          ]

          result = described_class.build_one_of(schemas, nil, version_3_1_0)

          expect(result[:oneOf][0]).to eq({ '$ref' => '#/components/schemas/Dog' })
          expect(result[:oneOf][1]).to eq({ '$ref' => '#/components/schemas/Cat' })
        end
      end

      context 'when mixed schemas in oneOf' do
        it 'handles mix of refs and inline schemas' do
          schemas = [
            'Dog',
            { type: 'object', properties: { name: { type: 'string' } } }
          ]

          result = described_class.build_one_of(schemas, nil, version_3_1_0)

          expect(result[:oneOf][0]).to eq({ '$ref' => '#/components/schemas/Dog' })
          expect(result[:oneOf][1]).to eq({ type: 'object', properties: { name: { type: 'string' } } })
        end
      end

      context 'when Swagger 2.0 is used' do
        it 'returns nil (oneOf not supported in Swagger 2.0)' do
          schemas = ['SuccessResponse', 'ErrorResponse']

          result = described_class.build_one_of(schemas, nil, version_2_0)

          expect(result).to be_nil
        end
      end
    end
  end

  describe '.build_any_of' do
    # Story 14.3: AnyOf Schema Support
    context 'Story 14.3: AnyOf Schema Support' do
      context 'when anyOf with two schemas' do
        it 'creates anyOf array with schema refs' do
          schemas = ['BaseSchema', 'ExtensionSchema']

          result = described_class.build_any_of(schemas, nil, version_3_1_0)

          expect(result).to be_a(Hash)
          expect(result[:anyOf]).to be_a(Array)
          expect(result[:anyOf].size).to eq(2)
        end

        it 'converts schema names to component refs' do
          schemas = ['BaseSchema', 'ExtensionSchema']

          result = described_class.build_any_of(schemas, nil, version_3_1_0)

          expect(result[:anyOf][0]).to eq({ '$ref' => '#/components/schemas/BaseSchema' })
          expect(result[:anyOf][1]).to eq({ '$ref' => '#/components/schemas/ExtensionSchema' })
        end
      end

      context 'when anyOf with multiple schemas' do
        it 'handles three or more schemas' do
          schemas = ['Required', 'OptionalA', 'OptionalB', 'OptionalC']

          result = described_class.build_any_of(schemas, nil, version_3_1_0)

          expect(result[:anyOf].size).to eq(4)
        end
      end

      context 'when anyOf with discriminator' do
        it 'includes discriminator object' do
          schemas = ['TypeA', 'TypeB']
          discriminator = {
            property_name: 'type'
          }

          result = described_class.build_any_of(schemas, discriminator, version_3_1_0)

          expect(result[:discriminator]).not_to be_nil
          expect(result[:discriminator][:propertyName]).to eq('type')
        end
      end

      context 'when anyOf for optional extension' do
        it 'combines base schema with optional extensions' do
          schemas = [
            { type: 'object', properties: { required: { type: 'string' } } },
            { type: 'object', properties: { optional: { type: 'string' } } }
          ]

          result = described_class.build_any_of(schemas, nil, version_3_1_0)

          expect(result[:anyOf].size).to eq(2)
          expect(result[:anyOf][0][:properties]).to have_key(:required)
          expect(result[:anyOf][1][:properties]).to have_key(:optional)
        end
      end

      context 'when anyOf with nullable type' do
        it 'handles nullable as one of the anyOf options' do
          schemas = [
            'StringSchema',
            { type: 'null' }
          ]

          result = described_class.build_any_of(schemas, nil, version_3_1_0)

          expect(result[:anyOf][0]).to eq({ '$ref' => '#/components/schemas/StringSchema' })
          expect(result[:anyOf][1]).to eq({ type: 'null' })
        end
      end

      context 'when Swagger 2.0 is used' do
        it 'returns nil (anyOf not supported in Swagger 2.0)' do
          schemas = ['SchemaA', 'SchemaB']

          result = described_class.build_any_of(schemas, nil, version_2_0)

          expect(result).to be_nil
        end
      end
    end
  end

  describe '.build_all_of' do
    # Story 14.4: Polymorphic Entity Support
    context 'Story 14.4: Polymorphic Entity Support' do
      context 'when entity inheritance generates allOf' do
        it 'creates allOf with base and extension schemas' do
          base = 'Pet'
          extension = {
            type: 'object',
            properties: {
              breed: { type: 'string' },
              barkVolume: { type: 'integer' }
            }
          }

          result = described_class.build_all_of(base, extension, version_3_1_0)

          expect(result).to be_a(Hash)
          expect(result[:allOf]).to be_a(Array)
          expect(result[:allOf].size).to eq(2)
        end

        it 'converts base schema name to component ref' do
          base = 'Pet'
          extension = { type: 'object', properties: {} }

          result = described_class.build_all_of(base, extension, version_3_1_0)

          expect(result[:allOf][0]).to eq({ '$ref' => '#/components/schemas/Pet' })
          expect(result[:allOf][1]).to eq(extension)
        end
      end

      context 'when child entity extends parent' do
        it 'references parent as $ref in allOf' do
          base = 'Animal'
          extension = {
            type: 'object',
            properties: {
              species: { type: 'string' }
            }
          }

          result = described_class.build_all_of(base, extension, version_3_1_0)

          expect(result[:allOf][0]['$ref']).to eq('#/components/schemas/Animal')
        end

        it 'includes child-specific properties in extension' do
          base = 'Vehicle'
          extension = {
            type: 'object',
            properties: {
              wheels: { type: 'integer' },
              engine: { type: 'string' }
            }
          }

          result = described_class.build_all_of(base, extension, version_3_1_0)

          expect(result[:allOf][1][:properties]).to have_key(:wheels)
          expect(result[:allOf][1][:properties]).to have_key(:engine)
        end
      end

      context 'when base is already a ref object' do
        it 'preserves existing ref format' do
          base = { '$ref' => '#/components/schemas/BaseEntity' }
          extension = { type: 'object', properties: {} }

          result = described_class.build_all_of(base, extension, version_3_1_0)

          expect(result[:allOf][0]).to eq({ '$ref' => '#/components/schemas/BaseEntity' })
        end
      end

      context 'when used with Swagger 2.0' do
        it 'still creates allOf (supported in Swagger 2.0)' do
          base = 'Pet'
          extension = { type: 'object', properties: { breed: { type: 'string' } } }

          result = described_class.build_all_of(base, extension, version_2_0)

          expect(result[:allOf]).not_to be_nil
          expect(result[:allOf].size).to eq(2)
        end
      end
    end
  end

  # Edge cases
  describe 'edge cases' do
    context 'when empty schemas array' do
      it 'handles empty array for oneOf' do
        result = described_class.build_one_of([], nil, version_3_1_0)

        expect(result[:oneOf]).to eq([])
      end

      it 'handles empty array for anyOf' do
        result = described_class.build_any_of([], nil, version_3_1_0)

        expect(result[:anyOf]).to eq([])
      end
    end

    context 'when schemas with external refs' do
      it 'preserves external refs in oneOf' do
        schemas = [
          { '$ref' => 'https://example.com/schemas/External' },
          'Local'
        ]

        result = described_class.build_one_of(schemas, nil, version_3_1_0)

        expect(result[:oneOf][0]['$ref']).to eq('https://example.com/schemas/External')
        expect(result[:oneOf][1]['$ref']).to eq('#/components/schemas/Local')
      end
    end
  end
end
