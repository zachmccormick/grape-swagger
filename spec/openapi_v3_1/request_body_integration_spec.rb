# frozen_string_literal: true

require 'spec_helper'

# Test API with POST/PUT endpoints for request body integration
class RequestBodyTestAPI < Grape::API
  format :json

  resource :users do
    desc 'Create a user'
    params do
      requires :name, type: String, desc: 'User name'
      requires :email, type: String, desc: 'User email'
      optional :age, type: Integer, desc: 'User age'
    end
    post do
      { id: 1, name: params[:name], email: params[:email] }
    end

    desc 'Update a user'
    params do
      requires :id, type: Integer, desc: 'User ID'
      optional :name, type: String, desc: 'User name'
      optional :email, type: String, desc: 'User email'
    end
    put ':id' do
      { id: params[:id], name: params[:name] }
    end

    desc 'Get all users'
    params do
      optional :filter, type: String, desc: 'Filter string'
    end
    get do
      []
    end

    desc 'Delete a user'
    params do
      requires :id, type: Integer, desc: 'User ID'
    end
    delete ':id' do
      nil
    end
  end

  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'Request Body Test API',
      description: 'Test API for request body integration',
      version: '1.0.0'
    }
  )
end

# Swagger 2.0 version of same API for comparison
class RequestBodySwagger2API < Grape::API
  format :json

  resource :items do
    desc 'Create an item'
    params do
      requires :name, type: String, desc: 'Item name'
      optional :price, type: Float, desc: 'Item price'
    end
    post do
      { id: 1, name: params[:name] }
    end
  end

  add_swagger_documentation(
    info: {
      title: 'Swagger 2 Test API',
      description: 'Test API for Swagger 2.0',
      version: '1.0.0'
    }
  )
end

describe 'Request Body Integration' do
  context 'OpenAPI 3.1.0 API' do
    def app
      RequestBodyTestAPI
    end

    let(:swagger_doc) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates valid swagger documentation' do
      expect(swagger_doc).to be_a(Hash)
    end

    context 'POST endpoint' do
      let(:post_method) { swagger_doc['paths']['/users']['post'] }

      it 'includes requestBody for POST endpoint' do
        expect(post_method).to have_key('requestBody')
      end

      it 'includes content in requestBody' do
        request_body = post_method['requestBody']
        expect(request_body).to have_key('content')
      end

      it 'includes application/json content type' do
        content = post_method['requestBody']['content']
        expect(content).to have_key('application/json')
      end

      it 'includes schema in content type' do
        json_content = post_method['requestBody']['content']['application/json']
        expect(json_content).to have_key('schema')
      end

      it 'does not include body parameters in parameters array' do
        # POST with only body params should have no parameters array,
        # or only non-body params remaining
        params = post_method['parameters']
        if params
          body_params = params.select { |p| p['in'] == 'body' }
          expect(body_params).to be_empty
        end
      end
    end

    context 'PUT endpoint' do
      let(:put_method) { swagger_doc['paths']['/users/{id}']['put'] }

      it 'includes requestBody for PUT endpoint' do
        expect(put_method).to have_key('requestBody')
      end

      it 'keeps path parameters in parameters array' do
        params = put_method['parameters']
        # There should be path params remaining (id is in the path)
        if params
          path_params = params.select { |p| p['in'] == 'path' }
          expect(path_params).not_to be_empty
        end
      end

      it 'does not include body parameters in parameters array' do
        params = put_method['parameters']
        if params
          body_params = params.select { |p| p['in'] == 'body' }
          expect(body_params).to be_empty
        end
      end
    end

    context 'GET endpoint' do
      let(:get_method) { swagger_doc['paths']['/users']['get'] }

      it 'does not include requestBody for GET endpoint' do
        expect(get_method).not_to have_key('requestBody')
      end

      it 'keeps query parameters in parameters array' do
        params = get_method['parameters']
        if params
          query_params = params.select { |p| p['in'] == 'query' }
          expect(query_params).not_to be_empty
        end
      end
    end

    context 'DELETE endpoint' do
      let(:delete_method) { swagger_doc['paths']['/users/{id}']['delete'] }

      it 'does not include requestBody for DELETE endpoint' do
        expect(delete_method).not_to have_key('requestBody')
      end
    end
  end

  context 'Swagger 2.0 API (backward compatibility)' do
    def app
      RequestBodySwagger2API
    end

    let(:swagger_doc) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'does not include requestBody for Swagger 2.0' do
      post_method = swagger_doc['paths']['/items']['post']
      expect(post_method).not_to have_key('requestBody')
    end

    it 'keeps body parameters in parameters array for Swagger 2.0' do
      post_method = swagger_doc['paths']['/items']['post']
      params = post_method['parameters']
      expect(params).not_to be_nil
    end

    it 'uses swagger 2.0 format' do
      expect(swagger_doc).to have_key('swagger')
      expect(swagger_doc['swagger']).to eq('2.0')
    end
  end
end
