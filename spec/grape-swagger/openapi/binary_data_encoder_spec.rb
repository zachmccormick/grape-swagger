# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::BinaryDataEncoder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.encode' do
    context 'OpenAPI 3.1.0' do
      context 'binary format' do
        it 'transforms binary format to contentEncoding and contentMediaType' do
          schema = { type: 'string', format: 'binary' }
          result = described_class.encode(schema, version_3_1_0)

          expect(result[:type]).to eq('string')
          expect(result[:contentEncoding]).to eq('base64')
          expect(result[:contentMediaType]).to eq('application/octet-stream')
          expect(result).not_to have_key(:format)
        end

        it 'preserves other properties with binary format' do
          schema = {
            type: 'string',
            format: 'binary',
            description: 'File upload'
          }
          result = described_class.encode(schema, version_3_1_0)

          expect(result[:contentEncoding]).to eq('base64')
          expect(result[:contentMediaType]).to eq('application/octet-stream')
          expect(result[:description]).to eq('File upload')
          expect(result).not_to have_key(:format)
        end
      end

      context 'byte format' do
        it 'transforms byte format to contentEncoding only' do
          schema = { type: 'string', format: 'byte' }
          result = described_class.encode(schema, version_3_1_0)

          expect(result[:type]).to eq('string')
          expect(result[:contentEncoding]).to eq('base64')
          expect(result).not_to have_key(:format)
          expect(result).not_to have_key(:contentMediaType)
        end

        it 'preserves other properties with byte format' do
          schema = {
            type: 'string',
            format: 'byte',
            description: 'Base64 encoded data'
          }
          result = described_class.encode(schema, version_3_1_0)

          expect(result[:contentEncoding]).to eq('base64')
          expect(result[:description]).to eq('Base64 encoded data')
          expect(result).not_to have_key(:format)
        end
      end

      context 'custom media types' do
        it 'supports custom contentMediaType for images' do
          schema = {
            type: 'string',
            format: 'binary',
            contentMediaType: 'image/png'
          }
          result = described_class.encode(schema, version_3_1_0)

          expect(result[:contentEncoding]).to eq('base64')
          expect(result[:contentMediaType]).to eq('image/png')
          expect(result).not_to have_key(:format)
        end

        it 'supports custom contentMediaType for PDFs' do
          schema = {
            type: 'string',
            format: 'binary',
            contentMediaType: 'application/pdf'
          }
          result = described_class.encode(schema, version_3_1_0)

          expect(result[:contentEncoding]).to eq('base64')
          expect(result[:contentMediaType]).to eq('application/pdf')
        end

        it 'supports custom contentMediaType for JSON' do
          schema = {
            type: 'string',
            format: 'binary',
            contentMediaType: 'application/json'
          }
          result = described_class.encode(schema, version_3_1_0)

          expect(result[:contentEncoding]).to eq('base64')
          expect(result[:contentMediaType]).to eq('application/json')
        end
      end

      context 'non-binary formats' do
        it 'does not transform email format' do
          schema = { type: 'string', format: 'email' }
          result = described_class.encode(schema, version_3_1_0)

          expect(result).to eq({ type: 'string', format: 'email' })
          expect(result).not_to have_key(:contentEncoding)
        end

        it 'does not transform date format' do
          schema = { type: 'string', format: 'date' }
          result = described_class.encode(schema, version_3_1_0)

          expect(result).to eq({ type: 'string', format: 'date' })
          expect(result).not_to have_key(:contentEncoding)
        end

        it 'does not transform date-time format' do
          schema = { type: 'string', format: 'date-time' }
          result = described_class.encode(schema, version_3_1_0)

          expect(result).to eq({ type: 'string', format: 'date-time' })
        end

        it 'does not transform uuid format' do
          schema = { type: 'string', format: 'uuid' }
          result = described_class.encode(schema, version_3_1_0)

          expect(result).to eq({ type: 'string', format: 'uuid' })
        end
      end

      context 'edge cases' do
        it 'handles schema without format' do
          schema = { type: 'string' }
          result = described_class.encode(schema, version_3_1_0)

          expect(result).to eq({ type: 'string' })
        end

        it 'handles empty schema' do
          schema = {}
          result = described_class.encode(schema, version_3_1_0)

          expect(result).to eq({})
        end
      end

      context 'multiple binary fields' do
        it 'handles multiple binary schemas independently' do
          schema1 = { type: 'string', format: 'binary' }
          schema2 = { type: 'string', format: 'byte' }

          result1 = described_class.encode(schema1, version_3_1_0)
          result2 = described_class.encode(schema2, version_3_1_0)

          expect(result1[:contentMediaType]).to eq('application/octet-stream')
          expect(result2).not_to have_key(:contentMediaType)
          expect(result1[:contentEncoding]).to eq('base64')
          expect(result2[:contentEncoding]).to eq('base64')
        end
      end
    end

    context 'Swagger 2.0' do
      it 'preserves format: binary for Swagger 2.0' do
        schema = { type: 'string', format: 'binary' }
        result = described_class.encode(schema, version_2_0)

        expect(result[:type]).to eq('string')
        expect(result[:format]).to eq('binary')
        expect(result).not_to have_key(:contentEncoding)
        expect(result).not_to have_key(:contentMediaType)
      end

      it 'preserves format: byte for Swagger 2.0' do
        schema = { type: 'string', format: 'byte' }
        result = described_class.encode(schema, version_2_0)

        expect(result[:type]).to eq('string')
        expect(result[:format]).to eq('byte')
        expect(result).not_to have_key(:contentEncoding)
      end
    end

    context 'immutability' do
      it 'does not mutate the original schema' do
        original_schema = { type: 'string', format: 'binary' }
        schema = original_schema.dup
        described_class.encode(schema, version_3_1_0)

        expect(original_schema).to eq({ type: 'string', format: 'binary' })
      end
    end
  end
end
