# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::ParameterSchemaWrapper do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.wrap' do
    # Story 7.1: Parameter Schema Wrapping - Tests for wrapping type/format/enum in schema
    context 'Story 7.1: Parameter Schema Wrapping' do
      context 'query parameter' do
        it 'wraps type in schema object for OpenAPI 3.1.0' do
          parameter = { name: 'filter', in: 'query', type: 'string' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result).to have_key(:schema)
          expect(result[:schema]).to have_key(:type)
          expect(result[:schema][:type]).to eq('string')
          expect(result).not_to have_key(:type)
        end

        it 'does not wrap for Swagger 2.0' do
          parameter = { name: 'filter', in: 'query', type: 'string' }

          result = described_class.wrap(parameter, version_2_0)

          expect(result).not_to have_key(:schema)
          expect(result).to have_key(:type)
          expect(result[:type]).to eq('string')
        end

        it 'wraps format in schema object' do
          parameter = { name: 'created_at', in: 'query', type: 'string', format: 'date-time' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to have_key(:format)
          expect(result[:schema][:format]).to eq('date-time')
          expect(result).not_to have_key(:format)
        end

        it 'wraps enum in schema object' do
          parameter = { name: 'status', in: 'query', type: 'string', enum: %w[active inactive] }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to have_key(:enum)
          expect(result[:schema][:enum]).to eq(%w[active inactive])
          expect(result).not_to have_key(:enum)
        end

        it 'wraps default in schema object' do
          parameter = { name: 'page', in: 'query', type: 'integer', default: 1 }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to have_key(:default)
          expect(result[:schema][:default]).to eq(1)
          expect(result).not_to have_key(:default)
        end

        it 'wraps minimum and maximum in schema object' do
          parameter = { name: 'age', in: 'query', type: 'integer', minimum: 0, maximum: 120 }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to have_key(:minimum)
          expect(result[:schema]).to have_key(:maximum)
          expect(result[:schema][:minimum]).to eq(0)
          expect(result[:schema][:maximum]).to eq(120)
          expect(result).not_to have_key(:minimum)
          expect(result).not_to have_key(:maximum)
        end

        it 'wraps minLength and maxLength in schema object' do
          parameter = { name: 'username', in: 'query', type: 'string', minLength: 3, maxLength: 20 }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to have_key(:minLength)
          expect(result[:schema]).to have_key(:maxLength)
          expect(result[:schema][:minLength]).to eq(3)
          expect(result[:schema][:maxLength]).to eq(20)
          expect(result).not_to have_key(:minLength)
          expect(result).not_to have_key(:maxLength)
        end

        it 'wraps pattern in schema object' do
          parameter = { name: 'email', in: 'query', type: 'string', pattern: '^[a-z]+@[a-z]+\.[a-z]+$' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to have_key(:pattern)
          expect(result[:schema][:pattern]).to eq('^[a-z]+@[a-z]+\.[a-z]+$')
          expect(result).not_to have_key(:pattern)
        end

        it 'wraps items in schema object for array types' do
          parameter = { name: 'tags', in: 'query', type: 'array', items: { type: 'string' } }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to have_key(:items)
          expect(result[:schema][:items]).to eq({ type: 'string' })
          expect(result).not_to have_key(:items)
        end

        it 'preserves non-schema fields at parameter level' do
          parameter = {
            name: 'search',
            in: 'query',
            type: 'string',
            required: true,
            description: 'Search query'
          }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:name]).to eq('search')
          expect(result[:in]).to eq('query')
          expect(result[:required]).to be true
          expect(result[:description]).to eq('Search query')
        end

        it 'handles multiple schema fields together' do
          parameter = {
            name: 'score',
            in: 'query',
            type: 'number',
            format: 'float',
            minimum: 0.0,
            maximum: 100.0,
            default: 50.0
          }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to eq({
            type: 'number',
            format: 'float',
            minimum: 0.0,
            maximum: 100.0,
            default: 50.0
          })
          expect(result).not_to have_key(:type)
          expect(result).not_to have_key(:format)
        end
      end

      context 'path parameter' do
        it 'wraps schema for path parameters' do
          parameter = { name: 'id', in: 'path', type: 'integer', required: true }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to have_key(:type)
          expect(result[:schema][:type]).to eq('integer')
          expect(result[:required]).to be true
        end

        it 'wraps format for path parameters' do
          parameter = { name: 'uuid', in: 'path', type: 'string', format: 'uuid', required: true }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema][:type]).to eq('string')
          expect(result[:schema][:format]).to eq('uuid')
        end
      end

      context 'header parameter' do
        it 'wraps schema for header parameters' do
          parameter = { name: 'X-API-Key', in: 'header', type: 'string' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema]).to have_key(:type)
          expect(result[:schema][:type]).to eq('string')
        end

        it 'wraps pattern for header parameters' do
          parameter = { name: 'X-Request-ID', in: 'header', type: 'string', pattern: '^[0-9a-f]{8}$' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:schema][:pattern]).to eq('^[0-9a-f]{8}$')
        end
      end
    end

    # Story 7.2: Cookie Parameters - Tests for cookie parameter support
    context 'Story 7.2: Cookie Parameters' do
      it 'supports cookie parameter location' do
        parameter = { name: 'session_id', in: 'cookie', type: 'string' }

        result = described_class.wrap(parameter, version_3_1_0)

        expect(result[:in]).to eq('cookie')
        expect(result[:schema]).to have_key(:type)
        expect(result[:schema][:type]).to eq('string')
      end

      it 'wraps schema for cookie parameters' do
        parameter = { name: 'auth_token', in: 'cookie', type: 'string', format: 'uuid' }

        result = described_class.wrap(parameter, version_3_1_0)

        expect(result[:schema][:type]).to eq('string')
        expect(result[:schema][:format]).to eq('uuid')
      end

      it 'supports required cookie parameters' do
        parameter = { name: 'csrf_token', in: 'cookie', type: 'string', required: true }

        result = described_class.wrap(parameter, version_3_1_0)

        expect(result[:required]).to be true
        expect(result[:schema][:type]).to eq('string')
      end

      it 'supports optional cookie parameters with default' do
        parameter = { name: 'theme', in: 'cookie', type: 'string', default: 'light', enum: %w[light dark] }

        result = described_class.wrap(parameter, version_3_1_0)

        expect(result[:schema][:default]).to eq('light')
        expect(result[:schema][:enum]).to eq(%w[light dark])
      end

      it 'supports cookie description' do
        parameter = {
          name: 'session_id',
          in: 'cookie',
          type: 'string',
          description: 'Session identifier'
        }

        result = described_class.wrap(parameter, version_3_1_0)

        expect(result[:description]).to eq('Session identifier')
        expect(result[:schema][:type]).to eq('string')
      end
    end

    # Story 7.3: Parameter Serialization - Tests for serialization options
    context 'Story 7.3: Parameter Serialization' do
      context 'style option' do
        it 'defaults to form style for query parameters' do
          parameter = { name: 'ids', in: 'query', type: 'array', items: { type: 'integer' } }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:style]).to eq('form')
        end

        it 'defaults to simple style for path parameters' do
          parameter = { name: 'id', in: 'path', type: 'integer', required: true }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:style]).to eq('simple')
        end

        it 'defaults to simple style for header parameters' do
          parameter = { name: 'X-API-Key', in: 'header', type: 'string' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:style]).to eq('simple')
        end

        it 'defaults to form style for cookie parameters' do
          parameter = { name: 'session_id', in: 'cookie', type: 'string' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:style]).to eq('form')
        end

        it 'preserves explicit style value' do
          parameter = { name: 'filter', in: 'query', type: 'array', items: { type: 'string' }, style: 'spaceDelimited' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:style]).to eq('spaceDelimited')
        end

        it 'supports pipeDelimited style' do
          parameter = { name: 'filter', in: 'query', type: 'array', items: { type: 'string' }, style: 'pipeDelimited' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:style]).to eq('pipeDelimited')
        end

        it 'supports deepObject style for nested objects' do
          parameter = { name: 'filter', in: 'query', type: 'object', style: 'deepObject' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:style]).to eq('deepObject')
        end
      end

      context 'explode option' do
        it 'sets explode true by default for form style query arrays' do
          parameter = { name: 'tags', in: 'query', type: 'array', items: { type: 'string' } }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:explode]).to be true
        end

        it 'sets explode false by default for simple style path arrays' do
          parameter = { name: 'ids', in: 'path', type: 'array', items: { type: 'integer' }, required: true }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:explode]).to be false
        end

        it 'preserves explicit explode value' do
          parameter = { name: 'filter', in: 'query', type: 'array', items: { type: 'string' }, explode: false }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:explode]).to be false
        end

        it 'does not set explode for non-array/object types' do
          parameter = { name: 'name', in: 'query', type: 'string' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result).not_to have_key(:explode)
        end
      end

      context 'allowReserved option' do
        it 'includes allowReserved when explicitly set' do
          parameter = { name: 'url', in: 'query', type: 'string', allowReserved: true }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:allowReserved]).to be true
        end

        it 'does not include allowReserved by default' do
          parameter = { name: 'filter', in: 'query', type: 'string' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result).not_to have_key(:allowReserved)
        end

        it 'preserves allowReserved false when explicitly set' do
          parameter = { name: 'path', in: 'query', type: 'string', allowReserved: false }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:allowReserved]).to be false
        end
      end

      context 'allowEmptyValue option' do
        it 'includes allowEmptyValue when explicitly set' do
          parameter = { name: 'search', in: 'query', type: 'string', allowEmptyValue: true }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result[:allowEmptyValue]).to be true
        end

        it 'does not include allowEmptyValue by default' do
          parameter = { name: 'filter', in: 'query', type: 'string' }

          result = described_class.wrap(parameter, version_3_1_0)

          expect(result).not_to have_key(:allowEmptyValue)
        end
      end
    end

    # Edge cases
    context 'edge cases' do
      it 'handles parameters with no schema fields' do
        parameter = { name: 'custom', in: 'query', description: 'Custom parameter' }

        result = described_class.wrap(parameter, version_3_1_0)

        expect(result[:name]).to eq('custom')
        expect(result[:in]).to eq('query')
        expect(result[:description]).to eq('Custom parameter')
        # Schema should not be present if there are no schema fields
      end

      it 'does not mutate the original parameter' do
        original = { name: 'id', in: 'query', type: 'integer' }
        parameter = original.dup

        described_class.wrap(parameter, version_3_1_0)

        expect(parameter).to eq({ name: 'id', in: 'query', type: 'integer' })
      end

      it 'handles parameters with custom extensions' do
        parameter = {
          name: 'filter',
          in: 'query',
          type: 'string',
          :'x-custom' => 'value'
        }

        result = described_class.wrap(parameter, version_3_1_0)

        expect(result[:'x-custom']).to eq('value')
        expect(result[:schema][:type]).to eq('string')
      end
    end
  end
end
