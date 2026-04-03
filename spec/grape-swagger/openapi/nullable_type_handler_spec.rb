# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::NullableTypeHandler do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.transform' do
    context 'OpenAPI 3.1.0' do
      context 'nullable string types' do
        it 'transforms nullable string to type array ["string", "null"]' do
          schema = { type: 'string', nullable: true }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['string', 'null'])
          expect(result).not_to have_key(:nullable)
        end

        it 'preserves non-nullable string as single type' do
          schema = { type: 'string' }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq('string')
          expect(result).not_to have_key(:nullable)
        end

        it 'preserves string with nullable: false as single type' do
          schema = { type: 'string', nullable: false }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq('string')
          expect(result).not_to have_key(:nullable)
        end
      end

      context 'nullable integer types' do
        it 'transforms nullable integer to type array ["integer", "null"]' do
          schema = { type: 'integer', nullable: true }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['integer', 'null'])
          expect(result).not_to have_key(:nullable)
        end

        it 'preserves non-nullable integer as single type' do
          schema = { type: 'integer' }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq('integer')
        end
      end

      context 'nullable number types' do
        it 'transforms nullable number to type array ["number", "null"]' do
          schema = { type: 'number', nullable: true }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['number', 'null'])
          expect(result).not_to have_key(:nullable)
        end
      end

      context 'nullable boolean types' do
        it 'transforms nullable boolean to type array ["boolean", "null"]' do
          schema = { type: 'boolean', nullable: true }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['boolean', 'null'])
          expect(result).not_to have_key(:nullable)
        end
      end

      context 'nullable array types' do
        it 'transforms nullable array and preserves items schema' do
          schema = { type: 'array', nullable: true, items: { type: 'string' } }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['array', 'null'])
          expect(result[:items]).to eq({ type: 'string' })
          expect(result).not_to have_key(:nullable)
        end

        it 'preserves non-nullable array with items' do
          schema = { type: 'array', items: { type: 'integer' } }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq('array')
          expect(result[:items]).to eq({ type: 'integer' })
        end
      end

      context 'nullable object types' do
        it 'transforms nullable object and preserves properties' do
          schema = {
            type: 'object',
            nullable: true,
            properties: {
              name: { type: 'string' },
              age: { type: 'integer' }
            }
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['object', 'null'])
          expect(result[:properties][:name]).to eq({ type: 'string' })
          expect(result[:properties][:age]).to eq({ type: 'integer' })
          expect(result).not_to have_key(:nullable)
        end
      end

      context 'nullable with enum' do
        it 'transforms nullable enum and preserves enum values' do
          schema = { type: 'string', nullable: true, enum: %w[red green blue] }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['string', 'null'])
          expect(result[:enum]).to eq(%w[red green blue])
          expect(result).not_to have_key(:nullable)
        end
      end

      context 'nullable with other properties' do
        it 'preserves format, description, and other metadata' do
          schema = {
            type: 'string',
            nullable: true,
            format: 'email',
            description: 'User email address',
            example: 'user@example.com'
          }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['string', 'null'])
          expect(result[:format]).to eq('email')
          expect(result[:description]).to eq('User email address')
          expect(result[:example]).to eq('user@example.com')
          expect(result).not_to have_key(:nullable)
        end
      end

      context 'type array deduplication' do
        it 'prevents duplicate "null" in type array' do
          schema = { type: ['string', 'null'], nullable: true }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['string', 'null'])
          expect(result[:type].count('null')).to eq(1)
        end

        it 'handles already array type with nullable' do
          schema = { type: ['string', 'integer'], nullable: true }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:type]).to eq(['string', 'integer', 'null'])
        end
      end

      context 'edge cases' do
        it 'handles empty schema' do
          schema = {}
          result = described_class.transform(schema, version_3_1_0)

          expect(result).to eq({})
        end

        it 'handles schema without type but with nullable' do
          schema = { nullable: true, description: 'Any value' }
          result = described_class.transform(schema, version_3_1_0)

          expect(result[:description]).to eq('Any value')
          expect(result).not_to have_key(:nullable)
          expect(result).not_to have_key(:type)
        end

        it 'handles nil schema' do
          result = described_class.transform(nil, version_3_1_0)

          expect(result).to be_nil
        end
      end
    end

    context 'Swagger 2.0' do
      it 'preserves nullable: true for Swagger 2.0' do
        schema = { type: 'string', nullable: true }
        result = described_class.transform(schema, version_2_0)

        expect(result[:type]).to eq('string')
        expect(result[:nullable]).to eq(true)
      end

      it 'preserves nullable integer for Swagger 2.0' do
        schema = { type: 'integer', nullable: true }
        result = described_class.transform(schema, version_2_0)

        expect(result[:type]).to eq('integer')
        expect(result[:nullable]).to eq(true)
      end

      it 'preserves nullable array for Swagger 2.0' do
        schema = { type: 'array', nullable: true, items: { type: 'string' } }
        result = described_class.transform(schema, version_2_0)

        expect(result[:type]).to eq('array')
        expect(result[:nullable]).to eq(true)
        expect(result[:items]).to eq({ type: 'string' })
      end
    end

    context 'immutability' do
      it 'does not mutate the original schema' do
        original_schema = { type: 'string', nullable: true }
        schema = original_schema.dup
        described_class.transform(schema, version_3_1_0)

        expect(original_schema).to eq({ type: 'string', nullable: true })
      end
    end
  end
end
