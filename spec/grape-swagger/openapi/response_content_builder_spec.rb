# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::ResponseContentBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    context 'basic response structure' do
      it 'wraps response schema in content object' do
        response = {
          description: 'Success',
          schema: { type: 'object', properties: { id: { type: 'integer' } } }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result).to have_key(:content)
      end

      it 'includes media type key in content' do
        response = {
          description: 'Success',
          schema: { type: 'object' }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result[:content]).to have_key('application/json')
      end

      it 'nests schema under media type' do
        response = {
          description: 'Success',
          schema: { type: 'object', properties: { name: { type: 'string' } } }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result[:content]['application/json']).to have_key(:schema)
        expect(result[:content]['application/json'][:schema][:type]).to eq('object')
      end

      it 'preserves description at response level' do
        response = {
          description: 'Successfully created resource',
          schema: { type: 'object' }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result[:description]).to eq('Successfully created resource')
      end

      it 'keeps headers at response level, not inside content' do
        response = {
          description: 'Success',
          schema: { type: 'object' },
          headers: {
            'X-Rate-Limit': { type: 'integer', description: 'Rate limit' }
          }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result).to have_key(:headers)
        expect(result[:content]['application/json']).not_to have_key(:headers)
      end

      it 'transforms headers using HeaderBuilder for OpenAPI 3.1.0' do
        response = {
          description: 'Success',
          schema: { type: 'object' },
          headers: {
            'X-Rate-Limit': { type: 'integer', description: 'Rate limit' }
          }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        header = result[:headers][:'X-Rate-Limit']
        expect(header[:schema]).to eq({ type: 'integer' })
        expect(header[:description]).to eq('Rate limit')
      end
    end

    context 'multiple media types' do
      it 'supports multiple content types' do
        response = {
          description: 'Success',
          schema: { type: 'object' }
        }
        produces = ['application/json', 'application/xml']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result[:content]).to have_key('application/json')
        expect(result[:content]).to have_key('application/xml')
      end

      it 'includes schema for each media type' do
        response = {
          description: 'Success',
          schema: { type: 'object', properties: { id: { type: 'integer' } } }
        }
        produces = ['application/json', 'application/xml', 'text/plain']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result[:content]['application/json'][:schema]).to be_a(Hash)
        expect(result[:content]['application/xml'][:schema]).to be_a(Hash)
        expect(result[:content]['text/plain'][:schema]).to be_a(Hash)
      end
    end

    context 'without schema' do
      it 'returns description only when no schema provided' do
        response = {
          description: 'No content'
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result).to have_key(:description)
        expect(result).not_to have_key(:content)
      end

      it 'handles response with only headers' do
        response = {
          description: 'Partial content',
          headers: {
            'X-Total-Count': { type: 'integer' }
          }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result).to have_key(:description)
        expect(result).to have_key(:headers)
        expect(result).not_to have_key(:content)
      end
    end

    context 'schema with $ref' do
      it 'translates $ref in schema using SchemaResolver' do
        response = {
          description: 'Success',
          schema: { '$ref': '#/definitions/User' }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:$ref]).to eq('#/components/schemas/User')
      end

      it 'translates nested $ref in properties' do
        response = {
          description: 'Success',
          schema: {
            type: 'object',
            properties: {
              user: { '$ref': '#/definitions/User' },
              company: { '$ref': '#/definitions/Company' }
            }
          }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:properties][:user][:$ref]).to eq('#/components/schemas/User')
        expect(schema[:properties][:company][:$ref]).to eq('#/components/schemas/Company')
      end
    end

    context '$ref response passthrough' do
      it 'returns $ref response unchanged (symbol key)' do
        response = { :$ref => '#/components/responses/NotFound' }

        result = described_class.build(response, version_3_1_0, ['application/json'])

        expect(result).to eq(response)
      end

      it 'returns $ref response unchanged (string key)' do
        response = { '$ref' => '#/components/responses/NotFound' }

        result = described_class.build(response, version_3_1_0, ['application/json'])

        expect(result).to eq(response)
      end
    end

    context 'response examples' do
      it 'includes single example in content object' do
        response = {
          description: 'Success',
          schema: { type: 'object' },
          examples: { 'application/json': { id: 1, name: 'John' } }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        content = result[:content]['application/json']
        expect(content).to have_key(:example)
        expect(content[:example]).to eq({ id: 1, name: 'John' })
      end

      it 'includes named examples in examples map' do
        response = {
          description: 'Success',
          schema: { type: 'object' },
          examples: {
            'application/json': {
              basic: {
                summary: 'Basic example',
                value: { id: 1 }
              },
              detailed: {
                summary: 'Detailed example',
                value: { id: 1, name: 'John', email: 'john@example.com' }
              }
            }
          }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        content = result[:content]['application/json']
        expect(content).to have_key(:examples)
        expect(content[:examples]).to have_key(:basic)
        expect(content[:examples]).to have_key(:detailed)
      end

      it 'preserves summary and description in examples' do
        response = {
          description: 'Success',
          schema: { type: 'object' },
          examples: {
            'application/json': {
              basic: {
                summary: 'Basic example',
                description: 'A minimal example',
                value: { id: 1 }
              }
            }
          }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        example = result[:content]['application/json'][:examples][:basic]
        expect(example[:summary]).to eq('Basic example')
        expect(example[:description]).to eq('A minimal example')
        expect(example[:value]).to eq({ id: 1 })
      end

      it 'supports different examples per media type' do
        response = {
          description: 'Success',
          schema: { type: 'object' },
          examples: {
            'application/json': { id: 1, format: 'json' },
            'application/xml': '<user><id>1</id><format>xml</format></user>'
          }
        }
        produces = ['application/json', 'application/xml']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result[:content]['application/json'][:example]).to eq({ id: 1, format: 'json' })
        expect(result[:content]['application/xml'][:example]).to eq('<user><id>1</id><format>xml</format></user>')
      end
    end

    context 'status code handling' do
      it 'wraps 200 response schema in content' do
        response = {
          description: 'OK',
          schema: { type: 'object', properties: { data: { type: 'array' } } }
        }

        result = described_class.build(response, version_3_1_0, ['application/json'])

        expect(result).to have_key(:content)
        expect(result[:content]['application/json'][:schema]).to be_a(Hash)
      end

      it 'wraps 201 created response schema in content' do
        response = {
          description: 'Created',
          schema: { type: 'object', properties: { id: { type: 'integer' } } }
        }

        result = described_class.build(response, version_3_1_0, ['application/json'])

        expect(result).to have_key(:content)
      end

      it 'does not include content for empty 204 No Content response' do
        response = {
          description: 'No Content'
        }

        result = described_class.build(response, version_3_1_0, ['application/json'])

        expect(result).to have_key(:description)
        expect(result).not_to have_key(:content)
      end

      it 'handles 204 with headers but no content' do
        response = {
          description: 'No Content',
          headers: {
            'X-Request-Id': { type: 'string' }
          }
        }

        result = described_class.build(response, version_3_1_0, ['application/json'])

        expect(result).to have_key(:description)
        expect(result).to have_key(:headers)
        expect(result).not_to have_key(:content)
      end

      it 'wraps 400 error schema in content' do
        response = {
          description: 'Bad Request',
          schema: { type: 'object', properties: { error: { type: 'string' } } }
        }

        result = described_class.build(response, version_3_1_0, ['application/json'])

        expect(result).to have_key(:content)
      end

      it 'wraps 500 error schema in content' do
        response = {
          description: 'Internal Server Error',
          schema: { type: 'object', properties: { message: { type: 'string' } } }
        }

        result = described_class.build(response, version_3_1_0, ['application/json'])

        expect(result).to have_key(:content)
      end
    end

    context 'version compatibility' do
      it 'returns original response structure for Swagger 2.0' do
        response = {
          description: 'Success',
          schema: { type: 'object' }
        }
        produces = ['application/json']

        result = described_class.build(response, version_2_0, produces)

        expect(result).to eq(response)
        expect(result).not_to have_key(:content)
      end

      it 'wraps response in content for OpenAPI 3.1.0' do
        response = {
          description: 'Success',
          schema: { type: 'object' }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result).to have_key(:content)
      end
    end

    context 'edge cases' do
      it 'defaults to application/json when produces is nil' do
        response = {
          description: 'Success',
          schema: { type: 'object' }
        }

        result = described_class.build(response, version_3_1_0, nil)

        expect(result).to have_key(:content)
        expect(result[:content]).to have_key('application/json')
      end

      it 'defaults to application/json when produces is empty' do
        response = {
          description: 'Success',
          schema: { type: 'object' }
        }

        result = described_class.build(response, version_3_1_0, [])

        expect(result).to have_key(:content)
        expect(result[:content]).to have_key('application/json')
      end

      it 'defaults to application/json when produces is omitted' do
        response = {
          description: 'Success',
          schema: { type: 'object' }
        }

        result = described_class.build(response, version_3_1_0)

        expect(result).to have_key(:content)
        expect(result[:content]).to have_key('application/json')
      end

      it 'handles response with all fields' do
        response = {
          description: 'Success',
          schema: { type: 'object', properties: { id: { type: 'integer' } } },
          headers: {
            'X-Rate-Limit': { type: 'integer' }
          },
          examples: { 'application/json': { id: 123 } }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        expect(result).to have_key(:description)
        expect(result).to have_key(:content)
        expect(result).to have_key(:headers)
        expect(result[:content]['application/json']).to have_key(:schema)
        expect(result[:content]['application/json']).to have_key(:example)
      end

      it 'handles array schema' do
        response = {
          description: 'List of users',
          schema: {
            type: 'array',
            items: { type: 'object', properties: { id: { type: 'integer' } } }
          }
        }
        produces = ['application/json']

        result = described_class.build(response, version_3_1_0, produces)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:type]).to eq('array')
        expect(schema[:items]).to be_a(Hash)
      end
    end
  end
end
