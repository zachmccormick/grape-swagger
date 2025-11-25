# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::AdditionalPropertiesHandler do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.apply' do
    context 'OpenAPI 3.1.0' do
      context 'additionalProperties: false' do
        it 'sets additionalProperties to false for strict schemas' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' }
            }
          }
          result = described_class.apply(schema, version_3_1_0, additional_properties: false)

          expect(result[:additionalProperties]).to eq(false)
        end

        it 'preserves existing properties' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' },
              age: { type: 'integer' }
            }
          }
          result = described_class.apply(schema, version_3_1_0, additional_properties: false)

          expect(result[:properties][:name]).to eq({ type: 'string' })
          expect(result[:properties][:age]).to eq({ type: 'integer' })
          expect(result[:additionalProperties]).to eq(false)
        end
      end

      context 'additionalProperties: true' do
        it 'sets additionalProperties to true to allow any properties' do
          schema = {
            type: 'object',
            properties: {
              id: { type: 'string' }
            }
          }
          result = described_class.apply(schema, version_3_1_0, additional_properties: true)

          expect(result[:additionalProperties]).to eq(true)
        end
      end

      context 'additionalProperties with schema' do
        it 'sets additionalProperties to a schema for typed additional properties' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' }
            }
          }
          additional_schema = { type: 'string' }
          result = described_class.apply(
            schema,
            version_3_1_0,
            additional_properties: additional_schema
          )

          expect(result[:additionalProperties]).to eq({ type: 'string' })
        end

        it 'allows complex schemas for additionalProperties' do
          schema = {
            type: 'object',
            properties: {
              id: { type: 'string' }
            }
          }
          additional_schema = {
            type: 'object',
            properties: {
              value: { type: 'string' },
              timestamp: { type: 'string', format: 'date-time' }
            }
          }
          result = described_class.apply(
            schema,
            version_3_1_0,
            additional_properties: additional_schema
          )

          expect(result[:additionalProperties]).to eq(additional_schema)
        end
      end

      context 'unevaluatedProperties: false' do
        it 'sets unevaluatedProperties to false for OpenAPI 3.1.0' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' }
            }
          }
          result = described_class.apply(schema, version_3_1_0, unevaluated_properties: false)

          expect(result[:unevaluatedProperties]).to eq(false)
        end

        it 'works with allOf composition' do
          schema = {
            allOf: [
              { '$ref': '#/components/schemas/Base' },
              {
                type: 'object',
                properties: {
                  extended_field: { type: 'string' }
                }
              }
            ]
          }
          result = described_class.apply(schema, version_3_1_0, unevaluated_properties: false)

          expect(result[:unevaluatedProperties]).to eq(false)
          expect(result[:allOf]).to be_present
        end
      end

      context 'unevaluatedProperties with schema' do
        it 'sets unevaluatedProperties to a schema for typed unevaluated properties' do
          schema = {
            type: 'object',
            properties: {
              id: { type: 'string' }
            }
          }
          unevaluated_schema = { type: 'string' }
          result = described_class.apply(
            schema,
            version_3_1_0,
            unevaluated_properties: unevaluated_schema
          )

          expect(result[:unevaluatedProperties]).to eq({ type: 'string' })
        end
      end

      context 'combination with patternProperties' do
        it 'applies both patternProperties and additionalProperties' do
          schema = {
            type: 'object',
            properties: {
              id: { type: 'string' }
            }
          }
          result = described_class.apply(
            schema,
            version_3_1_0,
            pattern_properties: {
              '^x-': { type: 'string', description: 'Extension fields' }
            },
            additional_properties: false
          )

          expect(result[:patternProperties]).to eq({
            '^x-': { type: 'string', description: 'Extension fields' }
          })
          expect(result[:additionalProperties]).to eq(false)
        end

        it 'handles multiple pattern properties' do
          schema = {
            type: 'object',
            properties: {
              id: { type: 'string' }
            }
          }
          result = described_class.apply(
            schema,
            version_3_1_0,
            pattern_properties: {
              '^x-': { type: 'string' },
              '^attr_': { type: 'integer' }
            }
          )

          expect(result[:patternProperties]).to eq({
            '^x-': { type: 'string' },
            '^attr_': { type: 'integer' }
          })
        end

        it 'combines pattern properties with unevaluatedProperties' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' }
            }
          }
          result = described_class.apply(
            schema,
            version_3_1_0,
            pattern_properties: {
              '^[0-9]+$': { type: 'number' }
            },
            unevaluated_properties: false
          )

          expect(result[:patternProperties]).to eq({
            '^[0-9]+$': { type: 'number' }
          })
          expect(result[:unevaluatedProperties]).to eq(false)
        end
      end

      context 'patternProperties only' do
        it 'applies patternProperties without additionalProperties' do
          schema = {
            type: 'object',
            properties: {
              id: { type: 'string' }
            }
          }
          result = described_class.apply(
            schema,
            version_3_1_0,
            pattern_properties: {
              '^data_': { type: 'string' }
            }
          )

          expect(result[:patternProperties]).to eq({
            '^data_': { type: 'string' }
          })
          expect(result[:additionalProperties]).to be_nil
        end
      end

      context 'non-object types' do
        it 'does not apply to non-object types' do
          schema = { type: 'string' }
          result = described_class.apply(
            schema,
            version_3_1_0,
            additional_properties: false
          )

          expect(result[:additionalProperties]).to be_nil
          expect(result[:type]).to eq('string')
        end

        it 'does not apply to arrays' do
          schema = {
            type: 'array',
            items: { type: 'string' }
          }
          result = described_class.apply(
            schema,
            version_3_1_0,
            additional_properties: false
          )

          expect(result[:additionalProperties]).to be_nil
          expect(result[:type]).to eq('array')
        end
      end

      context 'no options provided' do
        it 'returns schema unchanged if no options' do
          schema = {
            type: 'object',
            properties: {
              name: { type: 'string' }
            }
          }
          result = described_class.apply(schema, version_3_1_0)

          expect(result).to eq(schema)
        end
      end

      context 'edge cases' do
        it 'handles empty schema' do
          schema = {}
          result = described_class.apply(schema, version_3_1_0, additional_properties: false)

          # Empty schema has no type, so additionalProperties not applied
          expect(result).to eq({})
        end

        it 'handles object without properties' do
          schema = { type: 'object' }
          result = described_class.apply(schema, version_3_1_0, additional_properties: false)

          expect(result[:type]).to eq('object')
          expect(result[:additionalProperties]).to eq(false)
        end
      end
    end

    context 'Swagger 2.0' do
      it 'preserves additionalProperties for Swagger 2.0' do
        schema = {
          type: 'object',
          properties: {
            name: { type: 'string' }
          }
        }
        result = described_class.apply(schema, version_2_0, additional_properties: false)

        expect(result[:additionalProperties]).to eq(false)
      end

      it 'ignores unevaluatedProperties for Swagger 2.0 (not supported)' do
        schema = {
          type: 'object',
          properties: {
            name: { type: 'string' }
          }
        }
        result = described_class.apply(schema, version_2_0, unevaluated_properties: false)

        # unevaluatedProperties is not supported in Swagger 2.0
        expect(result[:unevaluatedProperties]).to be_nil
      end

      it 'uses x-patternProperties extension for Swagger 2.0' do
        schema = {
          type: 'object',
          properties: {
            id: { type: 'string' }
          }
        }
        result = described_class.apply(
          schema,
          version_2_0,
          pattern_properties: {
            '^x-': { type: 'string' }
          }
        )

        # For Swagger 2.0, use extension or ignore
        expect(result[:'x-patternProperties'] || result[:patternProperties]).to be_present
      end
    end

    context 'immutability' do
      it 'does not mutate the original schema' do
        original_schema = {
          type: 'object',
          properties: {
            name: { type: 'string' }
          }
        }
        schema = original_schema.dup
        described_class.apply(schema, version_3_1_0, additional_properties: false)

        expect(original_schema[:additionalProperties]).to be_nil
      end
    end
  end
end
