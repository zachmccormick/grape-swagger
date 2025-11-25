# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::EncodingBuilder do
  let(:version) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }

  # Story 6.3: Content Type Encoding - Tests for encoding builder
  describe '.build' do
    context 'with basic field encoding' do
      it 'builds encoding object for a single field' do
        field_name = :file
        encoding_config = { contentType: 'image/png' }

        result = described_class.build(field_name, encoding_config, version)

        expect(result).to have_key(:contentType)
        expect(result[:contentType]).to eq('image/png')
      end

      it 'returns nil when encoding config is nil' do
        result = described_class.build(:file, nil, version)

        expect(result).to be_nil
      end

      it 'returns nil when encoding config is empty' do
        result = described_class.build(:file, {}, version)

        expect(result).to be_nil
      end
    end

    context 'with contentType' do
      it 'includes contentType in encoding object' do
        encoding_config = { contentType: 'application/json' }

        result = described_class.build(:metadata, encoding_config, version)

        expect(result[:contentType]).to eq('application/json')
      end

      it 'handles multiple MIME types' do
        encoding_config = { contentType: 'application/octet-stream' }

        result = described_class.build(:file, encoding_config, version)

        expect(result[:contentType]).to eq('application/octet-stream')
      end
    end

    context 'with headers' do
      it 'includes headers in encoding object' do
        encoding_config = {
          headers: {
            'X-File-Name' => { schema: { type: 'string' } }
          }
        }

        result = described_class.build(:file, encoding_config, version)

        expect(result).to have_key(:headers)
        expect(result[:headers]).to have_key('X-File-Name')
      end

      it 'includes multiple headers' do
        encoding_config = {
          headers: {
            'X-File-Name' => { schema: { type: 'string' } },
            'X-File-Size' => { schema: { type: 'integer' } }
          }
        }

        result = described_class.build(:file, encoding_config, version)

        expect(result[:headers].keys).to contain_exactly('X-File-Name', 'X-File-Size')
      end

      it 'includes header schema details' do
        encoding_config = {
          headers: {
            'X-Custom' => {
              schema: { type: 'string', pattern: '^[A-Z]+$' },
              description: 'Custom header'
            }
          }
        }

        result = described_class.build(:field, encoding_config, version)

        expect(result[:headers]['X-Custom'][:schema][:type]).to eq('string')
        expect(result[:headers]['X-Custom'][:schema][:pattern]).to eq('^[A-Z]+$')
        expect(result[:headers]['X-Custom'][:description]).to eq('Custom header')
      end
    end

    context 'with style option' do
      it 'includes style when provided' do
        encoding_config = { style: 'form' }

        result = described_class.build(:tags, encoding_config, version)

        expect(result[:style]).to eq('form')
      end

      it 'supports different style values' do
        ['form', 'spaceDelimited', 'pipeDelimited', 'deepObject'].each do |style|
          encoding_config = { style: style }

          result = described_class.build(:field, encoding_config, version)

          expect(result[:style]).to eq(style)
        end
      end
    end

    context 'with explode option' do
      it 'includes explode when true' do
        encoding_config = { explode: true }

        result = described_class.build(:array_field, encoding_config, version)

        expect(result[:explode]).to be true
      end

      it 'includes explode when false' do
        encoding_config = { explode: false }

        result = described_class.build(:array_field, encoding_config, version)

        expect(result[:explode]).to be false
      end
    end

    context 'with allowReserved option' do
      it 'includes allowReserved when true' do
        encoding_config = { allowReserved: true }

        result = described_class.build(:query, encoding_config, version)

        expect(result[:allowReserved]).to be true
      end

      it 'includes allowReserved when false' do
        encoding_config = { allowReserved: false }

        result = described_class.build(:query, encoding_config, version)

        expect(result[:allowReserved]).to be false
      end
    end

    context 'with multiple options combined' do
      it 'builds complete encoding object with all options' do
        encoding_config = {
          contentType: 'application/json',
          headers: {
            'X-Meta' => { schema: { type: 'string' } }
          },
          style: 'form',
          explode: true,
          allowReserved: false
        }

        result = described_class.build(:complex_field, encoding_config, version)

        expect(result[:contentType]).to eq('application/json')
        expect(result[:headers]).to have_key('X-Meta')
        expect(result[:style]).to eq('form')
        expect(result[:explode]).to be true
        expect(result[:allowReserved]).to be false
      end
    end
  end

  describe '.build_for_fields' do
    context 'with multiple fields' do
      it 'builds encoding for multiple fields' do
        encoding_config = {
          file: { contentType: 'image/png' },
          metadata: { contentType: 'application/json' }
        }

        result = described_class.build_for_fields(encoding_config, version)

        expect(result).to have_key(:file)
        expect(result).to have_key(:metadata)
      end

      it 'includes encoding details for each field' do
        encoding_config = {
          file: { contentType: 'image/png', headers: { 'X-Name' => { schema: { type: 'string' } } } },
          tags: { style: 'form', explode: true }
        }

        result = described_class.build_for_fields(encoding_config, version)

        expect(result[:file][:contentType]).to eq('image/png')
        expect(result[:file][:headers]).to have_key('X-Name')
        expect(result[:tags][:style]).to eq('form')
        expect(result[:tags][:explode]).to be true
      end

      it 'skips fields with nil config' do
        encoding_config = {
          file: { contentType: 'image/png' },
          other: nil
        }

        result = described_class.build_for_fields(encoding_config, version)

        expect(result).to have_key(:file)
        expect(result).not_to have_key(:other)
      end

      it 'skips fields with empty config' do
        encoding_config = {
          file: { contentType: 'image/png' },
          other: {}
        }

        result = described_class.build_for_fields(encoding_config, version)

        expect(result).to have_key(:file)
        expect(result).not_to have_key(:other)
      end
    end

    context 'with nil or empty input' do
      it 'returns nil when encoding config is nil' do
        result = described_class.build_for_fields(nil, version)

        expect(result).to be_nil
      end

      it 'returns nil when encoding config is empty' do
        result = described_class.build_for_fields({}, version)

        expect(result).to be_nil
      end
    end
  end
end
