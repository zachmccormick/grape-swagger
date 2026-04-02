# frozen_string_literal: true

require 'spec_helper'

# Test API with various parameter types for schema wrapping integration
class ParameterSchemaTestAPI < Grape::API
  format :json

  resource :items do
    desc 'List items with query parameters'
    params do
      optional :filter, type: String, desc: 'Filter string'
      optional :page, type: Integer, desc: 'Page number'
      optional :per_page, type: Integer, desc: 'Items per page'
      optional :status, type: String, values: %w[active inactive archived], desc: 'Status filter'
    end
    get do
      []
    end

    desc 'Get a specific item'
    params do
      requires :id, type: Integer, desc: 'Item ID'
    end
    get ':id' do
      { id: params[:id] }
    end

    desc 'Create an item'
    params do
      requires :name, type: String, desc: 'Item name'
      optional :tags, type: Array[String], desc: 'Item tags'
      optional :price, type: Float, desc: 'Item price'
    end
    post do
      { id: 1, name: params[:name] }
    end

    desc 'Update an item'
    params do
      requires :id, type: Integer, desc: 'Item ID'
      optional :name, type: String, desc: 'Item name'
      optional :price, type: Float, desc: 'Item price'
    end
    put ':id' do
      { id: params[:id], name: params[:name] }
    end
  end

  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'Parameter Schema Test API',
      description: 'Test API for parameter schema wrapping',
      version: '1.0.0'
    }
  )
end

# Swagger 2.0 version for comparison
class ParameterSchemaSwagger2API < Grape::API
  format :json

  resource :items do
    desc 'List items'
    params do
      optional :filter, type: String, desc: 'Filter string'
      optional :status, type: String, values: %w[active inactive], desc: 'Status filter'
    end
    get do
      []
    end

    desc 'Get a specific item'
    params do
      requires :id, type: Integer, desc: 'Item ID'
    end
    get ':id' do
      { id: params[:id] }
    end
  end

  add_swagger_documentation(
    info: {
      title: 'Swagger 2 Parameter Test API',
      description: 'Test API for Swagger 2.0 parameters',
      version: '1.0.0'
    }
  )
end

describe 'Parameter Schema Wrapping Integration' do
  context 'OpenAPI 3.1.0 API' do
    def app
      ParameterSchemaTestAPI
    end

    let(:swagger_doc) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates valid swagger documentation' do
      expect(swagger_doc).to be_a(Hash)
    end

    context 'GET endpoint with query parameters' do
      let(:get_method) { swagger_doc['paths']['/items']['get'] }
      let(:parameters) { get_method['parameters'] }

      it 'has parameters array' do
        expect(parameters).to be_a(Array)
        expect(parameters).not_to be_empty
      end

      it 'wraps query parameter type in schema object' do
        filter_param = parameters.find { |p| p['name'] == 'filter' }
        expect(filter_param).not_to be_nil
        expect(filter_param).to have_key('schema')
        expect(filter_param['schema']).to have_key('type')
        expect(filter_param['schema']['type']).to eq('string')
      end

      it 'does not have type at parameter level' do
        filter_param = parameters.find { |p| p['name'] == 'filter' }
        expect(filter_param).not_to have_key('type')
      end

      it 'wraps integer type in schema object' do
        page_param = parameters.find { |p| p['name'] == 'page' }
        expect(page_param).not_to be_nil
        expect(page_param['schema']['type']).to eq('integer')
      end

      it 'wraps enum values in schema object' do
        status_param = parameters.find { |p| p['name'] == 'status' }
        expect(status_param).not_to be_nil
        expect(status_param['schema']).to have_key('enum')
        expect(status_param['schema']['enum']).to include('active', 'inactive', 'archived')
      end

      it 'adds style for query parameters' do
        filter_param = parameters.find { |p| p['name'] == 'filter' }
        expect(filter_param['style']).to eq('form')
      end

      it 'preserves parameter-level fields' do
        filter_param = parameters.find { |p| p['name'] == 'filter' }
        expect(filter_param['in']).to eq('query')
        expect(filter_param['name']).to eq('filter')
        expect(filter_param).to have_key('description')
      end
    end

    context 'GET endpoint with path parameter' do
      let(:get_method) { swagger_doc['paths']['/items/{id}']['get'] }
      let(:parameters) { get_method['parameters'] }

      it 'wraps path parameter type in schema object' do
        id_param = parameters.find { |p| p['name'] == 'id' }
        expect(id_param).not_to be_nil
        expect(id_param['schema']).to have_key('type')
        expect(id_param['schema']['type']).to eq('integer')
      end

      it 'adds simple style for path parameters' do
        id_param = parameters.find { |p| p['name'] == 'id' }
        expect(id_param['style']).to eq('simple')
      end

      it 'keeps required at parameter level' do
        id_param = parameters.find { |p| p['name'] == 'id' }
        expect(id_param['required']).to be true
      end
    end

    context 'POST endpoint (body params become requestBody)' do
      let(:post_method) { swagger_doc['paths']['/items']['post'] }

      it 'has requestBody instead of body parameters' do
        expect(post_method).to have_key('requestBody')
      end

      it 'has no body parameters in parameters array' do
        params = post_method['parameters']
        if params
          body_params = params.select { |p| p['in'] == 'body' || p['in'] == 'formData' }
          expect(body_params).to be_empty
        end
      end
    end

    context 'PUT endpoint with path and body params' do
      let(:put_method) { swagger_doc['paths']['/items/{id}']['put'] }
      let(:parameters) { put_method['parameters'] }

      it 'wraps remaining path parameters in schema' do
        if parameters
          id_param = parameters.find { |p| p['name'] == 'id' }
          if id_param
            expect(id_param['schema']).to have_key('type')
            expect(id_param['style']).to eq('simple')
          end
        end
      end

      it 'has requestBody for body params' do
        expect(put_method).to have_key('requestBody')
      end
    end
  end

  context 'Swagger 2.0 API (backward compatibility)' do
    def app
      ParameterSchemaSwagger2API
    end

    let(:swagger_doc) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    context 'GET endpoint with query parameters' do
      let(:get_method) { swagger_doc['paths']['/items']['get'] }
      let(:parameters) { get_method['parameters'] }

      it 'does NOT wrap parameter type in schema object' do
        filter_param = parameters.find { |p| p['name'] == 'filter' }
        expect(filter_param).not_to be_nil
        expect(filter_param).to have_key('type')
        expect(filter_param['type']).to eq('string')
        expect(filter_param).not_to have_key('schema')
      end

      it 'keeps type at parameter level' do
        status_param = parameters.find { |p| p['name'] == 'status' }
        expect(status_param).to have_key('type')
        expect(status_param).to have_key('enum')
      end

      it 'does not add style field' do
        filter_param = parameters.find { |p| p['name'] == 'filter' }
        expect(filter_param).not_to have_key('style')
      end
    end

    context 'GET endpoint with path parameter' do
      let(:get_method) { swagger_doc['paths']['/items/{id}']['get'] }
      let(:parameters) { get_method['parameters'] }

      it 'does NOT wrap path parameter in schema' do
        id_param = parameters.find { |p| p['name'] == 'id' }
        expect(id_param).to have_key('type')
        expect(id_param).not_to have_key('schema')
      end

      it 'does not add style field' do
        id_param = parameters.find { |p| p['name'] == 'id' }
        expect(id_param).not_to have_key('style')
      end
    end

    it 'uses swagger 2.0 format' do
      expect(swagger_doc).to have_key('swagger')
      expect(swagger_doc['swagger']).to eq('2.0')
    end
  end
end
