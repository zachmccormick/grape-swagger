# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::RequestBodyBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    # Story 4.1: Extract Body Parameters - Tests for body parameter extraction
    context 'Story 4.1: Extract Body Parameters' do
      context 'when method is POST' do
        it 'creates requestBody for POST with body parameters' do
          params = [
            { in: 'body', name: 'user', type: 'object', required: true, description: 'User object' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result).not_to be_nil
          expect(result).to have_key(:content)
          expect(result[:required]).to be true
        end

        it 'sets required field to true when body param is required' do
          params = [
            { in: 'body', name: 'data', type: 'object', required: true }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:required]).to be true
        end

        it 'sets required field to false when body param is not required' do
          params = [
            { in: 'body', name: 'data', type: 'object', required: false }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:required]).to be false
        end

        it 'maintains description from body parameter' do
          params = [
            { in: 'body', name: 'user', type: 'object', description: 'User information' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:description]).to eq('User information')
        end
      end

      context 'when method is PUT' do
        it 'creates requestBody for PUT with body parameters' do
          params = [
            { in: 'body', name: 'update', type: 'object' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'PUT', consumes, version_3_1_0)

          expect(result).not_to be_nil
          expect(result).to have_key(:content)
        end
      end

      context 'when method is PATCH' do
        it 'creates requestBody for PATCH with body parameters' do
          params = [
            { in: 'body', name: 'partial', type: 'object' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'PATCH', consumes, version_3_1_0)

          expect(result).not_to be_nil
          expect(result).to have_key(:content)
        end
      end

      context 'when method is GET' do
        it 'returns nil for GET requests' do
          params = [
            { in: 'query', name: 'filter', type: 'string' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'GET', consumes, version_3_1_0)

          expect(result).to be_nil
        end
      end

      context 'when method is DELETE' do
        it 'returns nil for DELETE requests' do
          params = [
            { in: 'path', name: 'id', type: 'integer' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'DELETE', consumes, version_3_1_0)

          expect(result).to be_nil
        end
      end

      context 'when no body parameters present' do
        it 'returns nil when only query parameters exist' do
          params = [
            { in: 'query', name: 'search', type: 'string' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result).to be_nil
        end

        it 'returns nil when only path parameters exist' do
          params = [
            { in: 'path', name: 'id', type: 'integer' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result).to be_nil
        end
      end

      context 'when body parameters are not in parameters array' do
        it 'extracts only body parameters from mixed parameter types' do
          params = [
            { in: 'query', name: 'filter', type: 'string' },
            { in: 'body', name: 'user', type: 'object' },
            { in: 'path', name: 'id', type: 'integer' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result).not_to be_nil
          expect(result).to have_key(:content)
        end
      end
    end

    # Story 4.2: Content Type Mapping - Tests for content type handling
    context 'Story 4.2: Content Type Mapping' do
      context 'application/json content type' do
        it 'creates content object with application/json media type' do
          params = [
            { in: 'body', name: 'data', type: 'object', properties: { name: { type: 'string' } } }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:content]).to have_key('application/json')
        end

        it 'includes schema in JSON content type' do
          params = [
            { in: 'body', name: 'data', type: 'object', properties: { name: { type: 'string' } } }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:content]['application/json']).to have_key(:schema)
        end
      end

      context 'application/xml content type' do
        it 'creates content object with application/xml media type' do
          params = [
            { in: 'body', name: 'data', type: 'object' }
          ]
          consumes = ['application/xml']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:content]).to have_key('application/xml')
        end

        it 'includes schema in XML content type' do
          params = [
            { in: 'body', name: 'data', type: 'object' }
          ]
          consumes = ['application/xml']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:content]['application/xml']).to have_key(:schema)
        end
      end

      context 'multipart/form-data content type' do
        it 'creates content object with multipart/form-data media type' do
          params = [
            { in: 'body', name: 'file', type: 'file' }
          ]
          consumes = ['multipart/form-data']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:content]).to have_key('multipart/form-data')
        end

        it 'includes schema with properties for form data' do
          params = [
            { in: 'body', name: 'file', type: 'file' },
            { in: 'body', name: 'description', type: 'string' }
          ]
          consumes = ['multipart/form-data']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          schema = result[:content]['multipart/form-data'][:schema]
          expect(schema).to have_key(:properties)
        end
      end

      context 'application/x-www-form-urlencoded content type' do
        it 'creates content object with application/x-www-form-urlencoded media type' do
          params = [
            { in: 'body', name: 'username', type: 'string' }
          ]
          consumes = ['application/x-www-form-urlencoded']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:content]).to have_key('application/x-www-form-urlencoded')
        end

        it 'includes schema with properties for URL encoded forms' do
          params = [
            { in: 'body', name: 'username', type: 'string' },
            { in: 'body', name: 'password', type: 'string' }
          ]
          consumes = ['application/x-www-form-urlencoded']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          schema = result[:content]['application/x-www-form-urlencoded'][:schema]
          expect(schema).to have_key(:properties)
          expect(schema[:properties]).to have_key(:username)
          expect(schema[:properties]).to have_key(:password)
        end
      end

      context 'multiple content types' do
        it 'creates content entries for each media type' do
          params = [
            { in: 'body', name: 'data', type: 'object' }
          ]
          consumes = ['application/json', 'application/xml']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:content]).to have_key('application/json')
          expect(result[:content]).to have_key('application/xml')
        end

        it 'includes schema for each content type' do
          params = [
            { in: 'body', name: 'data', type: 'object' }
          ]
          consumes = ['application/json', 'application/xml']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:content]['application/json'][:schema]).to be_a(Hash)
          expect(result[:content]['application/xml'][:schema]).to be_a(Hash)
        end
      end

      context 'schema structure' do
        it 'builds schema with type and properties for object parameters' do
          params = [
            { in: 'body', name: 'user', type: 'object', properties: { name: { type: 'string' }, age: { type: 'integer' } } }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          schema = result[:content]['application/json'][:schema]
          expect(schema[:type]).to eq('object')
          expect(schema[:properties]).to have_key(:name)
          expect(schema[:properties]).to have_key(:age)
        end

        it 'translates $ref in schema using SchemaResolver' do
          params = [
            { in: 'body', name: 'user', '$ref': '#/definitions/User' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          schema = result[:content]['application/json'][:schema]
          expect(schema[:$ref]).to eq('#/components/schemas/User')
        end
      end
    end

    # Story 4.3: Request Examples - Tests for example support
    context 'Story 4.3: Request Examples' do
      context 'single example' do
        it 'includes example in requestBody' do
          params = [
            { in: 'body', name: 'user', type: 'object', example: { name: 'John', age: 30 } }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          content = result[:content]['application/json']
          expect(content).to have_key(:example)
          expect(content[:example]).to eq({ name: 'John', age: 30 })
        end
      end

      context 'multiple named examples' do
        it 'includes examples object with named examples' do
          params = [
            {
              in: 'body',
              name: 'user',
              type: 'object',
              examples: {
                basic: {
                  summary: 'Basic user',
                  value: { name: 'John' }
                },
                detailed: {
                  summary: 'Detailed user',
                  value: { name: 'Jane', age: 25, email: 'jane@example.com' }
                }
              }
            }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          content = result[:content]['application/json']
          expect(content).to have_key(:examples)
          expect(content[:examples]).to have_key(:basic)
          expect(content[:examples]).to have_key(:detailed)
        end

        it 'includes summary and value in named examples' do
          params = [
            {
              in: 'body',
              name: 'user',
              type: 'object',
              examples: {
                basic: {
                  summary: 'Basic user',
                  value: { name: 'John' }
                }
              }
            }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          example = result[:content]['application/json'][:examples][:basic]
          expect(example[:summary]).to eq('Basic user')
          expect(example[:value]).to eq({ name: 'John' })
        end

        it 'includes description in named examples when provided' do
          params = [
            {
              in: 'body',
              name: 'user',
              type: 'object',
              examples: {
                basic: {
                  summary: 'Basic user',
                  description: 'A minimal user object',
                  value: { name: 'John' }
                }
              }
            }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          example = result[:content]['application/json'][:examples][:basic]
          expect(example[:description]).to eq('A minimal user object')
        end
      end

      context 'media type specific examples' do
        it 'supports different examples per media type' do
          params = [
            {
              in: 'body',
              name: 'data',
              type: 'object',
              examples: {
                json: { value: { format: 'json' } },
                xml: { value: { format: 'xml' } }
              }
            }
          ]
          consumes = ['application/json', 'application/xml']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result[:content]['application/json']).to have_key(:examples)
          expect(result[:content]['application/xml']).to have_key(:examples)
        end
      end
    end

    # Version compatibility tests
    context 'version compatibility' do
      context 'when version is Swagger 2.0' do
        it 'returns nil for Swagger 2.0' do
          params = [
            { in: 'body', name: 'data', type: 'object' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_2_0)

          expect(result).to be_nil
        end
      end

      context 'when version is OpenAPI 3.1.0' do
        it 'builds requestBody for OpenAPI 3.1.0' do
          params = [
            { in: 'body', name: 'data', type: 'object' }
          ]
          consumes = ['application/json']

          result = described_class.build(params, 'POST', consumes, version_3_1_0)

          expect(result).not_to be_nil
          expect(result).to have_key(:content)
        end
      end
    end

    # Edge cases
    context 'edge cases' do
      it 'handles empty consumes array' do
        params = [
          { in: 'body', name: 'data', type: 'object' }
        ]
        consumes = []

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result).to be_nil
      end

      it 'handles nil consumes' do
        params = [
          { in: 'body', name: 'data', type: 'object' }
        ]
        consumes = nil

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result).to be_nil
      end

      it 'handles multiple body parameters by merging them' do
        params = [
          { in: 'body', name: 'user', type: 'object', properties: { name: { type: 'string' } } },
          { in: 'body', name: 'settings', type: 'object', properties: { theme: { type: 'string' } } }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]).to have_key(:name)
        expect(schema[:properties]).to have_key(:theme)
      end
    end
  end
end
