# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::RequestBodyBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    context 'version checks' do
      it 'returns nil for Swagger 2.0' do
        params = [{ in: 'body', name: 'data', type: 'object', required: true }]
        result = described_class.build(params, 'POST', ['application/json'], version_2_0)
        expect(result).to be_nil
      end

      it 'returns request body for OpenAPI 3.1.0' do
        params = [{ in: 'body', name: 'data', type: 'object', required: true }]
        result = described_class.build(params, 'POST', ['application/json'], version_3_1_0)
        expect(result).to be_a(Hash)
        expect(result[:required]).to eq(true)
      end
    end

    context 'HTTP method checks' do
      let(:params) { [{ in: 'body', name: 'data', type: 'object' }] }
      let(:consumes) { ['application/json'] }

      it 'returns request body for POST' do
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        expect(result).to be_a(Hash)
      end

      it 'returns request body for PUT' do
        result = described_class.build(params, 'PUT', consumes, version_3_1_0)
        expect(result).to be_a(Hash)
      end

      it 'returns request body for PATCH' do
        result = described_class.build(params, 'PATCH', consumes, version_3_1_0)
        expect(result).to be_a(Hash)
      end

      it 'returns nil for GET' do
        result = described_class.build(params, 'GET', consumes, version_3_1_0)
        expect(result).to be_nil
      end

      it 'returns nil for DELETE' do
        result = described_class.build(params, 'DELETE', consumes, version_3_1_0)
        expect(result).to be_nil
      end
    end

    context 'parameter filtering' do
      let(:consumes) { ['application/json'] }

      it 'returns nil when no body parameters' do
        params = [{ in: 'query', name: 'filter', type: 'string' }]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        expect(result).to be_nil
      end

      it 'includes body parameters' do
        params = [
          { in: 'body', name: 'data', type: 'object', required: true },
          { in: 'query', name: 'filter', type: 'string' }
        ]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        expect(result).to be_a(Hash)
        expect(result[:required]).to eq(true)
      end

      it 'includes formData parameters' do
        params = [{ in: 'formData', name: 'file', type: 'file' }]
        result = described_class.build(params, 'POST', ['multipart/form-data'], version_3_1_0)
        expect(result).to be_a(Hash)
      end
    end

    context 'consumes validation' do
      let(:params) { [{ in: 'body', name: 'data', type: 'object' }] }

      it 'returns nil when consumes is nil' do
        result = described_class.build(params, 'POST', nil, version_3_1_0)
        expect(result).to be_nil
      end

      it 'returns nil when consumes is empty' do
        result = described_class.build(params, 'POST', [], version_3_1_0)
        expect(result).to be_nil
      end
    end

    context 'required determination' do
      let(:consumes) { ['application/json'] }

      it 'sets required true when any body param is required' do
        params = [
          { in: 'body', name: 'data', type: 'object', required: true },
          { in: 'body', name: 'optional_data', type: 'object', required: false }
        ]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        expect(result[:required]).to eq(true)
      end

      it 'sets required false when no body params are required' do
        params = [{ in: 'body', name: 'data', type: 'object', required: false }]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        expect(result[:required]).to eq(false)
      end
    end

    context 'schema building' do
      let(:consumes) { ['application/json'] }

      it 'uses $ref directly for single param with schema ref' do
        params = [{ in: 'body', name: 'pet', schema: { '$ref' => '#/definitions/Pet' } }]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        schema = result[:content]['application/json'][:schema]
        expect(schema[:$ref]).to eq('#/components/schemas/Pet')
      end

      it 'uses $ref directly for single param with symbol ref' do
        params = [{ in: 'body', name: 'pet', schema: { :$ref => '#/definitions/Pet' } }]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        schema = result[:content]['application/json'][:schema]
        expect(schema[:$ref]).to eq('#/components/schemas/Pet')
      end

      it 'uses $ref directly when param has top-level $ref' do
        params = [{ in: 'body', name: 'pet', :$ref => '#/definitions/Pet' }]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        schema = result[:content]['application/json'][:schema]
        expect(schema[:$ref]).to eq('#/components/schemas/Pet')
      end

      it 'builds schema from param type' do
        params = [{ in: 'body', name: 'data', type: 'object', properties: { name: { type: 'string' } } }]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        schema = result[:content]['application/json'][:schema]
        expect(schema[:type]).to eq('object')
        expect(schema[:properties]).to have_key(:name)
      end

      it 'merges multiple body parameters into single schema' do
        params = [
          { in: 'body', name: 'name', type: 'string', description: 'Name field' },
          { in: 'body', name: 'email', type: 'string', format: 'email' }
        ]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        schema = result[:content]['application/json'][:schema]
        expect(schema[:type]).to eq('object')
        expect(schema[:properties]).to have_key('name')
        expect(schema[:properties]).to have_key('email')
        expect(schema[:properties]['email'][:format]).to eq('email')
      end
    end

    context 'form data schema' do
      let(:consumes) { ['multipart/form-data'] }

      it 'builds form schema for multipart/form-data' do
        params = [
          { in: 'formData', name: 'file', type: 'file', description: 'Upload file' },
          { in: 'formData', name: 'name', type: 'string' }
        ]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        schema = result[:content]['multipart/form-data'][:schema]
        expect(schema[:type]).to eq('object')
        expect(schema[:properties]).to have_key(:file)
        expect(schema[:properties]).to have_key(:name)
      end

      it 'builds form schema for application/x-www-form-urlencoded' do
        params = [
          { in: 'formData', name: 'username', type: 'string' },
          { in: 'formData', name: 'password', type: 'string' }
        ]
        result = described_class.build(params, 'POST', ['application/x-www-form-urlencoded'], version_3_1_0)
        schema = result[:content]['application/x-www-form-urlencoded'][:schema]
        expect(schema[:type]).to eq('object')
      end
    end

    context 'description' do
      let(:consumes) { ['application/json'] }

      it 'includes description from first body param' do
        params = [{
          in: 'body',
          name: 'pet',
          type: 'object',
          description: 'Pet object to create'
        }]
        result = described_class.build(params, 'POST', consumes, version_3_1_0)
        expect(result[:description]).to eq('Pet object to create')
      end
    end

    context 'encoding' do
      it 'adds encoding for form data with file type' do
        params = [{
          in: 'formData',
          name: 'avatar',
          type: 'file'
        }]
        result = described_class.build(params, 'POST', ['multipart/form-data'], version_3_1_0)
        content = result[:content]['multipart/form-data']
        expect(content[:encoding]).to have_key(:avatar)
        expect(content[:encoding][:avatar][:contentType]).to eq('application/octet-stream')
      end

      it 'adds encoding for binary format' do
        params = [{
          in: 'formData',
          name: 'document',
          type: 'string',
          format: 'binary'
        }]
        result = described_class.build(params, 'POST', ['multipart/form-data'], version_3_1_0)
        content = result[:content]['multipart/form-data']
        expect(content[:encoding]).to have_key(:document)
      end

      it 'uses documentation encoding when provided' do
        params = [{
          in: 'formData',
          name: 'image',
          type: 'string',
          documentation: { encoding: { contentType: 'image/png' } }
        }]
        result = described_class.build(params, 'POST', ['multipart/form-data'], version_3_1_0)
        content = result[:content]['multipart/form-data']
        expect(content[:encoding][:image][:contentType]).to eq('image/png')
      end
    end
  end
end
