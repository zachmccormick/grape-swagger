# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::HeaderBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    context 'version compatibility' do
      it 'returns headers unchanged for Swagger 2.0' do
        headers = {
          'X-Rate-Limit' => { type: 'integer', description: 'Rate limit' }
        }

        result = described_class.build(headers, version_2_0)

        expect(result).to eq(headers)
      end

      it 'returns nil for nil headers' do
        result = described_class.build(nil, version_3_1_0)

        expect(result).to be_nil
      end

      it 'returns nil for empty headers' do
        result = described_class.build({}, version_3_1_0)

        expect(result).to be_nil
      end
    end

    context 'basic header transformation for OpenAPI 3.1.0' do
      it 'moves type into schema object' do
        headers = {
          'X-Rate-Limit' => { type: 'integer', description: 'Rate limit' }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Rate-Limit'][:schema]).to eq({ type: 'integer' })
        expect(result['X-Rate-Limit'][:description]).to eq('Rate limit')
        expect(result['X-Rate-Limit']).not_to have_key(:type)
      end

      it 'moves type and format into schema object' do
        headers = {
          'X-Request-Id' => { type: 'string', format: 'uuid', description: 'Request ID' }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Request-Id'][:schema]).to eq({ type: 'string', format: 'uuid' })
        expect(result['X-Request-Id'][:description]).to eq('Request ID')
      end

      it 'sets default style to simple' do
        headers = {
          'X-Token' => { type: 'string' }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Token'][:style]).to eq('simple')
      end

      it 'preserves description at header level' do
        headers = {
          'X-Token' => { type: 'string', description: 'Auth token' }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Token'][:description]).to eq('Auth token')
      end

      it 'preserves required at header level' do
        headers = {
          'X-Token' => { type: 'string', required: true }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Token'][:required]).to eq(true)
        expect(result['X-Token'][:schema]).to eq({ type: 'string' })
      end

      it 'preserves deprecated at header level' do
        headers = {
          'X-Old-Token' => { type: 'string', deprecated: true }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Old-Token'][:deprecated]).to eq(true)
      end
    end

    context 'schema fields' do
      it 'moves enum into schema' do
        headers = {
          'X-Priority' => { type: 'string', enum: %w[low medium high], description: 'Priority level' }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Priority'][:schema]).to eq({ type: 'string', enum: %w[low medium high] })
      end

      it 'moves default into schema' do
        headers = {
          'X-Page-Size' => { type: 'integer', default: 25 }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Page-Size'][:schema]).to eq({ type: 'integer', default: 25 })
      end

      it 'moves minimum and maximum into schema' do
        headers = {
          'X-Page' => { type: 'integer', minimum: 1, maximum: 1000 }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Page'][:schema]).to eq({ type: 'integer', minimum: 1, maximum: 1000 })
      end

      it 'moves pattern into schema' do
        headers = {
          'X-Correlation-Id' => { type: 'string', pattern: '^[a-f0-9-]+$' }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Correlation-Id'][:schema]).to eq({ type: 'string', pattern: '^[a-f0-9-]+$' })
      end
    end

    context 'multiple headers' do
      it 'transforms all headers' do
        headers = {
          'X-Rate-Limit' => { type: 'integer', description: 'Rate limit' },
          'X-Request-Id' => { type: 'string', format: 'uuid', description: 'Request ID' },
          'X-Total-Count' => { type: 'integer', description: 'Total items' }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result.keys).to eq(%w[X-Rate-Limit X-Request-Id X-Total-Count])
        expect(result['X-Rate-Limit'][:schema]).to eq({ type: 'integer' })
        expect(result['X-Request-Id'][:schema]).to eq({ type: 'string', format: 'uuid' })
        expect(result['X-Total-Count'][:schema]).to eq({ type: 'integer' })
      end
    end

    context 'already in 3.1.0 format' do
      it 'returns header unchanged if it already has schema' do
        headers = {
          'X-Token' => { schema: { type: 'string' }, description: 'Token' }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Token']).to eq({ schema: { type: 'string' }, description: 'Token' })
      end
    end

    context 'explode defaults' do
      it 'adds explode=false for array type headers' do
        headers = {
          'X-Tags' => { type: 'array', items: { type: 'string' } }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Tags'][:explode]).to eq(false)
        expect(result['X-Tags'][:schema]).to eq({ type: 'array', items: { type: 'string' } })
      end

      it 'does not add explode for simple type headers' do
        headers = {
          'X-Token' => { type: 'string' }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Token']).not_to have_key(:explode)
      end

      it 'preserves explicit explode value' do
        headers = {
          'X-Tags' => { type: 'array', items: { type: 'string' }, explode: true }
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Tags'][:explode]).to eq(true)
      end
    end

    context 'non-hash header definitions' do
      it 'returns non-hash header definitions as-is' do
        headers = {
          'X-Token' => 'some-string-value'
        }

        result = described_class.build(headers, version_3_1_0)

        expect(result['X-Token']).to eq('some-string-value')
      end
    end
  end
end
