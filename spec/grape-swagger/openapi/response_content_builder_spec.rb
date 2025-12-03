# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::ResponseContentBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    # Story 5.1: Response Content Structure - Tests for response content wrapping
    context 'Story 5.1: Response Content Structure' do
      context 'basic response structure' do
        it 'wraps response schema in content object' do
          response = {
            description: 'Success',
            schema: { type: 'object', properties: { id: { type: 'integer' } } }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result).to have_key(:content)
        end

        it 'includes media type key in content' do
          response = {
            description: 'Success',
            schema: { type: 'object' }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result[:content]).to have_key('application/json')
        end

        it 'nests schema under media type' do
          response = {
            description: 'Success',
            schema: { type: 'object', properties: { name: { type: 'string' } } }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result[:content]['application/json']).to have_key(:schema)
          expect(result[:content]['application/json'][:schema][:type]).to eq('object')
        end

        it 'preserves description at response level' do
          response = {
            description: 'Successfully created resource',
            schema: { type: 'object' }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

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

          result = described_class.build(response, produces, version_3_1_0)

          expect(result).to have_key(:headers)
          # Headers are transformed by HeaderBuilder for OpenAPI 3.1.0
          expect(result[:headers][:'X-Rate-Limit'][:description]).to eq('Rate limit')
          expect(result[:headers][:'X-Rate-Limit'][:schema][:type]).to eq('integer')
          expect(result[:content]['application/json']).not_to have_key(:headers)
        end
      end

      context 'multiple media types' do
        it 'supports multiple content types' do
          response = {
            description: 'Success',
            schema: { type: 'object' }
          }
          produces = ['application/json', 'application/xml']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result[:content]).to have_key('application/json')
          expect(result[:content]).to have_key('application/xml')
        end

        it 'includes schema for each media type' do
          response = {
            description: 'Success',
            schema: { type: 'object', properties: { id: { type: 'integer' } } }
          }
          produces = ['application/json', 'application/xml', 'text/plain']

          result = described_class.build(response, produces, version_3_1_0)

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

          result = described_class.build(response, produces, version_3_1_0)

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

          result = described_class.build(response, produces, version_3_1_0)

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

          result = described_class.build(response, produces, version_3_1_0)

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

          result = described_class.build(response, produces, version_3_1_0)

          schema = result[:content]['application/json'][:schema]
          expect(schema[:properties][:user][:$ref]).to eq('#/components/schemas/User')
          expect(schema[:properties][:company][:$ref]).to eq('#/components/schemas/Company')
        end
      end
    end

    # Story 5.2: Response Examples - Tests for example support
    context 'Story 5.2: Response Examples' do
      context 'single example' do
        it 'includes example in content object' do
          response = {
            description: 'Success',
            schema: { type: 'object' },
            examples: { 'application/json': { id: 1, name: 'John' } }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          content = result[:content]['application/json']
          expect(content).to have_key(:example)
          expect(content[:example]).to eq({ id: 1, name: 'John' })
        end
      end

      context 'multiple named examples' do
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

          result = described_class.build(response, produces, version_3_1_0)

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

          result = described_class.build(response, produces, version_3_1_0)

          example = result[:content]['application/json'][:examples][:basic]
          expect(example[:summary]).to eq('Basic example')
          expect(example[:description]).to eq('A minimal example')
          expect(example[:value]).to eq({ id: 1 })
        end
      end

      context 'media type specific examples' do
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

          result = described_class.build(response, produces, version_3_1_0)

          expect(result[:content]['application/json'][:example]).to eq({ id: 1, format: 'json' })
          expect(result[:content]['application/xml'][:example]).to eq('<user><id>1</id><format>xml</format></user>')
        end
      end

      context 'example generation from response definition' do
        it 'handles examples from Grape response definition' do
          response = {
            description: 'Success',
            schema: { type: 'object' },
            examples: { 'application/json': { success: true } }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result[:content]['application/json'][:example]).to eq({ success: true })
        end
      end
    end

    # Story 5.3: Status Code Handling - Tests for different status codes
    context 'Story 5.3: Status Code Handling' do
      context '200 response' do
        it 'wraps 200 response schema in content' do
          response = {
            description: 'OK',
            schema: { type: 'object', properties: { data: { type: 'array' } } }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result).to have_key(:content)
          expect(result[:content]['application/json'][:schema]).to be_a(Hash)
        end
      end

      context '201 response' do
        it 'wraps 201 created response schema in content' do
          response = {
            description: 'Created',
            schema: { type: 'object', properties: { id: { type: 'integer' } } }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result).to have_key(:content)
          expect(result[:content]['application/json'][:schema]).to be_a(Hash)
        end
      end

      context '204 response (empty)' do
        it 'does not include content for 204 No Content response' do
          response = {
            description: 'No Content'
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

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
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result).to have_key(:description)
          expect(result).to have_key(:headers)
          expect(result).not_to have_key(:content)
        end
      end

      context '400 error response' do
        it 'wraps 400 error schema in content' do
          response = {
            description: 'Bad Request',
            schema: { type: 'object', properties: { error: { type: 'string' } } }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result).to have_key(:content)
          expect(result[:content]['application/json'][:schema]).to be_a(Hash)
        end
      end

      context '500 error response' do
        it 'wraps 500 error schema in content' do
          response = {
            description: 'Internal Server Error',
            schema: { type: 'object', properties: { message: { type: 'string' } } }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result).to have_key(:content)
          expect(result[:content]['application/json'][:schema]).to be_a(Hash)
        end
      end

      context 'default response' do
        it 'wraps default response schema in content' do
          response = {
            description: 'Default response',
            schema: { type: 'object' }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result).to have_key(:content)
          expect(result[:content]['application/json'][:schema]).to be_a(Hash)
        end
      end
    end

    # Version compatibility tests
    context 'version compatibility' do
      context 'when version is Swagger 2.0' do
        it 'returns original response structure for Swagger 2.0' do
          response = {
            description: 'Success',
            schema: { type: 'object' }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_2_0)

          expect(result).to eq(response)
          expect(result).not_to have_key(:content)
        end
      end

      context 'when version is OpenAPI 3.1.0' do
        it 'wraps response in content for OpenAPI 3.1.0' do
          response = {
            description: 'Success',
            schema: { type: 'object' }
          }
          produces = ['application/json']

          result = described_class.build(response, produces, version_3_1_0)

          expect(result).to have_key(:content)
        end
      end
    end

    # Edge cases
    context 'edge cases' do
      it 'handles empty produces array' do
        response = {
          description: 'Success',
          schema: { type: 'object' }
        }
        produces = []

        result = described_class.build(response, produces, version_3_1_0)

        expect(result).to have_key(:description)
        expect(result).not_to have_key(:content)
      end

      it 'handles nil produces' do
        response = {
          description: 'Success',
          schema: { type: 'object' }
        }
        produces = nil

        result = described_class.build(response, produces, version_3_1_0)

        expect(result).to have_key(:description)
        expect(result).not_to have_key(:content)
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

        result = described_class.build(response, produces, version_3_1_0)

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

        result = described_class.build(response, produces, version_3_1_0)

        schema = result[:content]['application/json'][:schema]
        expect(schema[:type]).to eq('array')
        expect(schema[:items]).to be_a(Hash)
      end
    end
  end
end
