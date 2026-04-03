# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::ContentNegotiator do
  describe '.negotiate' do
    context 'when negotiating media types' do
      it 'returns prioritized request and response types' do
        consumes = ['application/json', 'application/xml']
        produces = ['application/json']

        result = described_class.negotiate(consumes, produces)

        expect(result).to have_key(:request_types)
        expect(result).to have_key(:response_types)
      end

      it 'prioritizes application/json first' do
        consumes = ['application/xml', 'application/json', 'multipart/form-data']

        result = described_class.negotiate(consumes, [])

        expect(result[:request_types].first).to eq('application/json')
      end

      it 'prioritizes application/xml second' do
        consumes = ['multipart/form-data', 'application/xml', 'application/x-www-form-urlencoded']

        result = described_class.negotiate(consumes, [])

        expect(result[:request_types].first).to eq('application/xml')
      end

      it 'prioritizes multipart/form-data third' do
        consumes = ['application/x-www-form-urlencoded', 'multipart/form-data']

        result = described_class.negotiate(consumes, [])

        expect(result[:request_types].first).to eq('multipart/form-data')
      end

      it 'handles wildcard types' do
        consumes = ['application/*', 'text/*']

        result = described_class.negotiate(consumes, [])

        expect(result[:request_types]).to include('application/*')
      end

      it 'preserves unknown media types in order' do
        consumes = ['application/custom', 'text/custom']

        result = described_class.negotiate(consumes, [])

        expect(result[:request_types]).to eq(['application/custom', 'text/custom'])
      end

      it 'handles empty consumes array' do
        result = described_class.negotiate([], ['application/json'])

        expect(result[:request_types]).to eq([])
      end

      it 'handles nil consumes' do
        result = described_class.negotiate(nil, ['application/json'])

        expect(result[:request_types]).to eq([])
      end
    end

    context 'when handling produces types' do
      it 'prioritizes produces types same as consumes' do
        produces = ['application/xml', 'application/json']

        result = described_class.negotiate([], produces)

        expect(result[:response_types].first).to eq('application/json')
      end
    end
  end

  describe '.build_content' do
    let(:version) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }

    context 'with single content type' do
      it 'builds content object with one media type' do
        types = ['application/json']
        schema = { type: 'object', properties: { id: { type: 'integer' } } }

        result = described_class.build_content(types, schema, nil, version)

        expect(result).to have_key('application/json')
        expect(result['application/json']).to have_key(:schema)
      end

      it 'includes schema in media type object' do
        types = ['application/json']
        schema = { type: 'object' }

        result = described_class.build_content(types, schema, nil, version)

        expect(result['application/json'][:schema]).to eq(schema)
      end
    end

    context 'with multiple content types' do
      it 'builds content object for each media type' do
        types = ['application/json', 'application/xml', 'text/plain']
        schema = { type: 'object' }

        result = described_class.build_content(types, schema, nil, version)

        expect(result.keys).to contain_exactly('application/json', 'application/xml', 'text/plain')
      end

      it 'includes same schema for all types by default' do
        types = ['application/json', 'application/xml']
        schema = { type: 'object', properties: { name: { type: 'string' } } }

        result = described_class.build_content(types, schema, nil, version)

        expect(result['application/json'][:schema]).to eq(schema)
        expect(result['application/xml'][:schema]).to eq(schema)
      end
    end

    context 'with examples' do
      it 'includes single example in content' do
        types = ['application/json']
        schema = { type: 'object' }
        examples = { example: { id: 1, name: 'Test' } }

        result = described_class.build_content(types, schema, examples, version)

        expect(result['application/json'][:example]).to eq({ id: 1, name: 'Test' })
      end

      it 'includes named examples in content' do
        types = ['application/json']
        schema = { type: 'object' }
        examples = {
          examples: {
            basic: { summary: 'Basic', value: { id: 1 } },
            detailed: { summary: 'Detailed', value: { id: 1, name: 'Test' } }
          }
        }

        result = described_class.build_content(types, schema, examples, version)

        expect(result['application/json'][:examples]).to have_key(:basic)
        expect(result['application/json'][:examples]).to have_key(:detailed)
      end

      it 'supports media-type-specific examples' do
        types = ['application/json', 'application/xml']
        schema = { type: 'object' }
        examples = {
          'application/json': { id: 1 },
          'application/xml': '<user><id>1</id></user>'
        }

        result = described_class.build_content(types, schema, examples, version)

        expect(result['application/json'][:example]).to eq({ id: 1 })
        expect(result['application/xml'][:example]).to eq('<user><id>1</id></user>')
      end
    end

    context 'with different schemas per content type' do
      it 'supports different schemas for different types' do
        types = ['application/json', 'application/xml']
        schemas = {
          'application/json': { type: 'object', properties: { id: { type: 'integer' } } },
          'application/xml': { type: 'string' }
        }

        result = described_class.build_content(types, schemas, nil, version)

        expect(result['application/json'][:schema][:type]).to eq('object')
        expect(result['application/xml'][:schema][:type]).to eq('string')
      end
    end
  end

  describe '.add_encoding' do
    let(:version) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }

    context 'when media type is multipart/form-data' do
      it 'adds encoding object to content' do
        content = {
          'multipart/form-data' => {
            schema: {
              type: 'object',
              properties: {
                file: { type: 'string', format: 'binary' },
                metadata: { type: 'object' }
              }
            }
          }
        }
        encoding_config = {
          file: { contentType: 'application/octet-stream' },
          metadata: { contentType: 'application/json' }
        }

        result = described_class.add_encoding(content, encoding_config, version)

        expect(result['multipart/form-data']).to have_key(:encoding)
      end

      it 'includes contentType in encoding' do
        content = {
          'multipart/form-data' => {
            schema: {
              type: 'object',
              properties: { file: { type: 'string', format: 'binary' } }
            }
          }
        }
        encoding_config = {
          file: { contentType: 'image/png' }
        }

        result = described_class.add_encoding(content, encoding_config, version)

        expect(result['multipart/form-data'][:encoding][:file][:contentType]).to eq('image/png')
      end

      it 'includes headers in encoding' do
        content = {
          'multipart/form-data' => {
            schema: {
              type: 'object',
              properties: { file: { type: 'string' } }
            }
          }
        }
        encoding_config = {
          file: { headers: { 'X-Custom-Header' => { schema: { type: 'string' } } } }
        }

        result = described_class.add_encoding(content, encoding_config, version)

        expect(result['multipart/form-data'][:encoding][:file][:headers]).to have_key('X-Custom-Header')
      end

      it 'includes style and explode options' do
        content = {
          'multipart/form-data' => {
            schema: {
              type: 'object',
              properties: { tags: { type: 'array' } }
            }
          }
        }
        encoding_config = {
          tags: { style: 'form', explode: true }
        }

        result = described_class.add_encoding(content, encoding_config, version)

        expect(result['multipart/form-data'][:encoding][:tags][:style]).to eq('form')
        expect(result['multipart/form-data'][:encoding][:tags][:explode]).to be true
      end

      it 'includes allowReserved option' do
        content = {
          'multipart/form-data' => {
            schema: {
              type: 'object',
              properties: { query: { type: 'string' } }
            }
          }
        }
        encoding_config = {
          query: { allowReserved: true }
        }

        result = described_class.add_encoding(content, encoding_config, version)

        expect(result['multipart/form-data'][:encoding][:query][:allowReserved]).to be true
      end
    end

    context 'when media type is not multipart' do
      it 'does not add encoding to non-multipart types' do
        content = {
          'application/json' => {
            schema: { type: 'object' }
          }
        }
        encoding_config = { field: { contentType: 'text/plain' } }

        result = described_class.add_encoding(content, encoding_config, version)

        expect(result['application/json']).not_to have_key(:encoding)
      end
    end

    context 'when encoding config is nil or empty' do
      it 'returns content unchanged when encoding is nil' do
        content = {
          'multipart/form-data' => {
            schema: { type: 'object' }
          }
        }

        result = described_class.add_encoding(content, nil, version)

        expect(result).to eq(content)
      end

      it 'returns content unchanged when encoding is empty' do
        content = {
          'multipart/form-data' => {
            schema: { type: 'object' }
          }
        }

        result = described_class.add_encoding(content, {}, version)

        expect(result).to eq(content)
      end
    end
  end
end
