# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::RequestBodyBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    context 'version compatibility' do
      it 'returns nil for Swagger 2.0' do
        params = [
          { in: 'body', name: 'data', type: 'object' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_2_0)

        expect(result).to be_nil
      end

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

    context 'HTTP method support' do
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

      it 'creates requestBody for PUT with body parameters' do
        params = [
          { in: 'body', name: 'update', type: 'object' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'PUT', consumes, version_3_1_0)

        expect(result).not_to be_nil
        expect(result).to have_key(:content)
      end

      it 'creates requestBody for PATCH with body parameters' do
        params = [
          { in: 'body', name: 'partial', type: 'object' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'PATCH', consumes, version_3_1_0)

        expect(result).not_to be_nil
        expect(result).to have_key(:content)
      end

      it 'returns nil for GET requests' do
        params = [
          { in: 'query', name: 'filter', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'GET', consumes, version_3_1_0)

        expect(result).to be_nil
      end

      it 'returns nil for DELETE requests' do
        params = [
          { in: 'path', name: 'id', type: 'integer' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'DELETE', consumes, version_3_1_0)

        expect(result).to be_nil
      end
    end

    context 'body parameter extraction' do
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

      it 'extracts formData parameters' do
        params = [
          { in: 'formData', name: 'file', type: 'file' }
        ]
        consumes = ['multipart/form-data']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result).not_to be_nil
        expect(result).to have_key(:content)
      end
    end

    context 'required field' do
      it 'sets required to true when body param is required' do
        params = [
          { in: 'body', name: 'data', type: 'object', required: true }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result[:required]).to be true
      end

      it 'sets required to false when body param is not required' do
        params = [
          { in: 'body', name: 'data', type: 'object', required: false }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result[:required]).to be false
      end
    end

    context 'description field' do
      it 'maintains description from body parameter' do
        params = [
          { in: 'body', name: 'user', type: 'object', description: 'User information' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result[:description]).to eq('User information')
      end

      it 'omits description when not provided' do
        params = [
          { in: 'body', name: 'user', type: 'object' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result[:description]).to be_nil
      end
    end

    context 'content type mapping' do
      it 'creates content object with application/json media type' do
        params = [
          { in: 'body', name: 'data', type: 'object', properties: { name: { type: 'string' } } }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result[:content]).to have_key('application/json')
        expect(result[:content]['application/json']).to have_key(:schema)
      end

      it 'creates content object with application/xml media type' do
        params = [
          { in: 'body', name: 'data', type: 'object' }
        ]
        consumes = ['application/xml']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result[:content]).to have_key('application/xml')
        expect(result[:content]['application/xml']).to have_key(:schema)
      end

      it 'creates content entries for multiple media types' do
        params = [
          { in: 'body', name: 'data', type: 'object' }
        ]
        consumes = ['application/json', 'application/xml']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        expect(result[:content]).to have_key('application/json')
        expect(result[:content]).to have_key('application/xml')
      end

      it 'defaults to application/json when consumes is nil' do
        params = [
          { in: 'body', name: 'data', type: 'object' }
        ]

        result = described_class.build(params, 'POST', nil, version_3_1_0)

        expect(result[:content]).to have_key('application/json')
      end

      it 'defaults to application/json when consumes is empty' do
        params = [
          { in: 'body', name: 'data', type: 'object' }
        ]

        result = described_class.build(params, 'POST', [], version_3_1_0)

        expect(result[:content]).to have_key('application/json')
      end
    end

    context 'schema building' do
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

      it 'handles $ref in nested schema hash' do
        params = [
          { in: 'body', name: 'user', schema: { '$ref' => '#/definitions/User' } }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:$ref]).to eq('#/components/schemas/User')
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

      it 'merges named parameters without properties' do
        params = [
          { in: 'body', name: 'username', type: 'string' },
          { in: 'body', name: 'password', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:type]).to eq('object')
        expect(schema[:properties]).to have_key('username')
        expect(schema[:properties]).to have_key('password')
      end
    end

    context 'form data schema' do
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
        expect(schema[:properties]).to have_key(:file)
        expect(schema[:properties]).to have_key(:description)
      end

      it 'creates content for application/x-www-form-urlencoded' do
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

    context 'Phase 6 schema field enhancements' do
      it 'includes title in property schema' do
        params = [
          { in: 'body', name: 'field', type: 'string', title: 'Field Title' },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]['field'][:title]).to eq('Field Title')
      end

      it 'includes not constraint in property schema' do
        params = [
          { in: 'body', name: 'field', type: 'string', not: { type: 'integer' } },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]['field'][:not]).to eq({ type: 'integer' })
      end

      it 'includes enum in property schema' do
        params = [
          { in: 'body', name: 'status', type: 'string', enum: %w[active inactive] },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]['status'][:enum]).to eq(%w[active inactive])
      end

      it 'includes default in property schema' do
        params = [
          { in: 'body', name: 'count', type: 'integer', default: 0 },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]['count'][:default]).to eq(0)
      end

      it 'includes readOnly in property schema' do
        params = [
          { in: 'body', name: 'id', type: 'integer', readOnly: true },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]['id'][:readOnly]).to be true
      end

      it 'includes writeOnly in property schema' do
        params = [
          { in: 'body', name: 'password', type: 'string', writeOnly: true },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]['password'][:writeOnly]).to be true
      end

      it 'includes minProperties and maxProperties in property schema' do
        params = [
          { in: 'body', name: 'metadata', type: 'object', minProperties: 1, maxProperties: 10 },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]['metadata'][:minProperties]).to eq(1)
        expect(schema[:properties]['metadata'][:maxProperties]).to eq(10)
      end

      it 'includes externalDocs in property schema' do
        external_docs = { url: 'https://example.com/docs', description: 'More info' }
        params = [
          { in: 'body', name: 'field', type: 'string', externalDocs: external_docs },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]['field'][:externalDocs]).to eq(external_docs)
      end

      it 'includes description in property schema' do
        params = [
          { in: 'body', name: 'field', type: 'string', description: 'A field desc' },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties]['field'][:description]).to eq('A field desc')
      end
    end

    context 'examples support' do
      it 'includes single example in requestBody' do
        params = [
          { in: 'body', name: 'user', type: 'object', example: { name: 'John', age: 30 } }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        content = result[:content]['application/json']
        expect(content).to have_key(:example)
        expect(content[:example]).to eq({ name: 'John', age: 30 })
      end

      it 'includes named examples in requestBody' do
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
        expect(content[:examples][:basic][:summary]).to eq('Basic user')
        expect(content[:examples][:basic][:value]).to eq({ name: 'John' })
      end
    end

    context 'array property support' do
      it 'includes items, minItems, maxItems, uniqueItems in property schema' do
        params = [
          {
            in: 'body', name: 'tags', type: 'array',
            items: { type: 'string' }, minItems: 1, maxItems: 10, uniqueItems: true
          },
          { in: 'body', name: 'other', type: 'string' }
        ]
        consumes = ['application/json']

        result = described_class.build(params, 'POST', consumes, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        tag_prop = schema[:properties]['tags']
        expect(tag_prop[:type]).to eq('array')
        expect(tag_prop[:items]).to eq({ type: 'string' })
        expect(tag_prop[:minItems]).to eq(1)
        expect(tag_prop[:maxItems]).to eq(10)
        expect(tag_prop[:uniqueItems]).to be true
      end
    end
  end
end
