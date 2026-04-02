# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::DocMethods do
  describe '.transform_definition_refs!' do
    it 'transforms $ref from #/definitions/ to #/components/schemas/' do
      obj = { '$ref' => '#/definitions/MyModel' }
      described_class.transform_definition_refs!(obj)
      expect(obj['$ref']).to eq('#/components/schemas/MyModel')
    end

    it 'transforms nested $ref values' do
      obj = {
        schema: { '$ref' => '#/definitions/User' },
        items: { '$ref' => '#/definitions/Item' }
      }
      described_class.transform_definition_refs!(obj)
      expect(obj[:schema]['$ref']).to eq('#/components/schemas/User')
      expect(obj[:items]['$ref']).to eq('#/components/schemas/Item')
    end

    it 'transforms $ref values inside arrays' do
      obj = {
        allOf: [
          { '$ref' => '#/definitions/Base' },
          { '$ref' => '#/definitions/Extension' }
        ]
      }
      described_class.transform_definition_refs!(obj)
      expect(obj[:allOf][0]['$ref']).to eq('#/components/schemas/Base')
      expect(obj[:allOf][1]['$ref']).to eq('#/components/schemas/Extension')
    end

    it 'does not modify non-definitions $ref values' do
      obj = { '$ref' => '#/parameters/SomeParam' }
      described_class.transform_definition_refs!(obj)
      expect(obj['$ref']).to eq('#/parameters/SomeParam')
    end

    it 'handles deeply nested structures' do
      obj = {
        paths: {
          '/users' => {
            get: {
              responses: {
                '200' => {
                  schema: { '$ref' => '#/definitions/UserList' }
                }
              }
            }
          }
        }
      }
      described_class.transform_definition_refs!(obj)
      expect(obj[:paths]['/users'][:get][:responses]['200'][:schema]['$ref']).to eq('#/components/schemas/UserList')
    end

    it 'handles nil and empty hashes gracefully' do
      expect { described_class.transform_definition_refs!(nil) }.not_to raise_error
      expect { described_class.transform_definition_refs!({}) }.not_to raise_error
      expect { described_class.transform_definition_refs!([]) }.not_to raise_error
    end
  end

  describe '.transform_file_types!' do
    it 'transforms type: file to type: string, format: binary with symbol keys' do
      obj = { type: 'file' }
      described_class.transform_file_types!(obj)
      expect(obj[:type]).to eq('string')
      expect(obj[:format]).to eq('binary')
    end

    it 'transforms type: file to type: string, format: binary with string keys' do
      obj = { 'type' => 'file' }
      described_class.transform_file_types!(obj)
      expect(obj['type']).to eq('string')
      expect(obj['format']).to eq('binary')
    end

    it 'transforms nested type: file values' do
      obj = {
        properties: {
          avatar: { type: 'file' },
          name: { type: 'string' }
        }
      }
      described_class.transform_file_types!(obj)
      expect(obj[:properties][:avatar][:type]).to eq('string')
      expect(obj[:properties][:avatar][:format]).to eq('binary')
      expect(obj[:properties][:name][:type]).to eq('string')
    end

    it 'transforms type: file inside arrays' do
      obj = {
        allOf: [
          { type: 'file' },
          { type: 'string' }
        ]
      }
      described_class.transform_file_types!(obj)
      expect(obj[:allOf][0][:type]).to eq('string')
      expect(obj[:allOf][0][:format]).to eq('binary')
      expect(obj[:allOf][1][:type]).to eq('string')
      expect(obj[:allOf][1]).not_to have_key(:format)
    end

    it 'does not modify non-file types' do
      obj = { type: 'integer' }
      described_class.transform_file_types!(obj)
      expect(obj[:type]).to eq('integer')
      expect(obj).not_to have_key(:format)
    end

    it 'handles nil and empty structures gracefully' do
      expect { described_class.transform_file_types!(nil) }.not_to raise_error
      expect { described_class.transform_file_types!({}) }.not_to raise_error
      expect { described_class.transform_file_types!([]) }.not_to raise_error
    end
  end

  describe '.normalize_tag' do
    it 'converts external_docs to externalDocs' do
      tag = { name: 'pets', external_docs: { url: 'http://example.com' } }
      result = described_class.normalize_tag(tag)
      expect(result[:externalDocs]).to eq({ url: 'http://example.com' })
      expect(result).not_to have_key(:external_docs)
    end

    it 'does not mutate the original tag' do
      tag = { name: 'pets', external_docs: { url: 'http://example.com' } }
      described_class.normalize_tag(tag)
      expect(tag).to have_key(:external_docs)
      expect(tag).not_to have_key(:externalDocs)
    end

    it 'returns tag unchanged when no external_docs present' do
      tag = { name: 'pets', description: 'Pet operations' }
      result = described_class.normalize_tag(tag)
      expect(result).to eq({ name: 'pets', description: 'Pet operations' })
    end

    it 'does not double-convert when externalDocs already present' do
      tag = { name: 'pets', externalDocs: { url: 'http://example.com' } }
      result = described_class.normalize_tag(tag)
      expect(result[:externalDocs]).to eq({ url: 'http://example.com' })
    end
  end

  describe '.output_path_definitions' do
    # Minimal test double for endpoint behavior
    let(:request) { double('request') }
    let(:endpoint) do
      double('endpoint').tap do |ep|
        allow(ep).to receive(:request).and_return(request)
        allow(ep).to receive(:swagger_object).and_return(swagger_object)
        allow(ep).to receive(:path_and_definition_objects).and_return([paths, definitions])
      end
    end

    let(:target_class) { double('target_class') }
    let(:paths) { { '/pets' => { get: { summary: 'List pets' } } } }
    let(:definitions) { { 'Pet' => { type: 'object', properties: { name: { type: 'string' } } } } }

    context 'when generating Swagger 2.0 spec' do
      let(:swagger_object) { { swagger: '2.0', info: { title: 'Test' } } }

      it 'places definitions at root level' do
        options = {}
        result = described_class.output_path_definitions(
          { pets: [] }, endpoint, target_class, options
        )
        expect(result).to have_key(:definitions)
        expect(result[:definitions]).to eq(definitions)
        expect(result).not_to have_key(:components)
      end
    end

    context 'when generating OpenAPI 3.x spec' do
      let(:swagger_object) { { openapi: '3.1.0', info: { title: 'Test' } } }

      it 'places definitions under components/schemas' do
        options = {}
        result = described_class.output_path_definitions(
          { pets: [] }, endpoint, target_class, options
        )
        expect(result).not_to have_key(:definitions)
        expect(result[:components][:schemas]).to eq(definitions)
      end

      it 'transforms $ref paths in the output' do
        definitions_with_refs = {
          'Pet' => {
            type: 'object',
            properties: {
              owner: { '$ref' => '#/definitions/Owner' }
            }
          }
        }
        allow(endpoint).to receive(:path_and_definition_objects).and_return([paths, definitions_with_refs])

        result = described_class.output_path_definitions(
          { pets: [] }, endpoint, target_class, {}
        )
        expect(result[:components][:schemas]['Pet'][:properties][:owner]['$ref']).to eq('#/components/schemas/Owner')
      end

      it 'transforms type: file in the output' do
        paths_with_file = {
          '/upload' => {
            post: {
              parameters: [{ name: 'file', in: 'formData', type: 'file' }]
            }
          }
        }
        allow(endpoint).to receive(:path_and_definition_objects).and_return([paths_with_file, definitions])

        result = described_class.output_path_definitions(
          { upload: [] }, endpoint, target_class, {}
        )
        param = result[:paths]['/upload'][:post][:parameters][0]
        expect(param[:type]).to eq('string')
        expect(param[:format]).to eq('binary')
      end

      it 'preserves existing components' do
        swagger_with_components = {
          openapi: '3.1.0',
          info: { title: 'Test' },
          components: { securitySchemes: { bearer: { type: 'http' } } }
        }
        allow(endpoint).to receive(:swagger_object).and_return(swagger_with_components)

        result = described_class.output_path_definitions(
          { pets: [] }, endpoint, target_class, {}
        )
        expect(result[:components][:securitySchemes]).to eq({ bearer: { type: 'http' } })
        expect(result[:components][:schemas]).to eq(definitions)
      end
    end

    context 'tag normalization' do
      let(:swagger_object) { { swagger: '2.0', info: { title: 'Test' } } }

      it 'normalizes custom tags with external_docs' do
        options = {
          tags: [
            { name: 'pets', external_docs: { url: 'http://example.com/pets' } }
          ]
        }
        result = described_class.output_path_definitions(
          { pets: [] }, endpoint, target_class, options
        )
        tag = result[:tags].find { |t| t[:name] == 'pets' }
        expect(tag[:externalDocs]).to eq({ url: 'http://example.com/pets' })
        expect(tag).not_to have_key(:external_docs)
      end
    end
  end
end
