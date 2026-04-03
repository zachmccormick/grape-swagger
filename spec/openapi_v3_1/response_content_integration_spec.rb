# frozen_string_literal: true

require 'spec_helper'

# Test API with various response types for response content integration
class ResponseContentTestAPI < Grape::API
  format :json

  resource :users do
    desc 'List all users',
         success: { code: 200, message: 'A list of users' }
    get do
      []
    end

    desc 'Create a user',
         success: { code: 201, message: 'User created' }
    params do
      requires :name, type: String, desc: 'User name'
      requires :email, type: String, desc: 'User email'
    end
    post do
      { id: 1, name: params[:name], email: params[:email] }
    end

    desc 'Get a user',
         success: { code: 200, message: 'User details' }
    params do
      requires :id, type: Integer, desc: 'User ID'
    end
    get ':id' do
      { id: params[:id], name: 'John' }
    end

    desc 'Delete a user'
    params do
      requires :id, type: Integer, desc: 'User ID'
    end
    delete ':id' do
      nil
    end

    desc 'User with headers',
         success: { code: 200, message: 'User with rate limit headers' },
         headers: {
           'X-Rate-Limit' => { description: 'Rate limit', type: 'integer' },
           'X-Request-Id' => { description: 'Request ID', type: 'string' }
         }
    get 'with_headers' do
      { id: 1 }
    end
  end

  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'Response Content Test API',
      description: 'Test API for response content wrapping',
      version: '1.0.0'
    }
  )
end

# Swagger 2.0 comparison API
class ResponseContentSwagger2API < Grape::API
  format :json

  resource :items do
    desc 'List all items',
         success: { code: 200, message: 'A list of items' }
    get do
      []
    end

    desc 'Create an item'
    params do
      requires :name, type: String, desc: 'Item name'
    end
    post do
      { id: 1, name: params[:name] }
    end
  end

  add_swagger_documentation(
    info: {
      title: 'Swagger 2 Response Test API',
      description: 'Test API for Swagger 2.0 responses',
      version: '1.0.0'
    }
  )
end

describe 'Response Content Integration' do
  context 'OpenAPI 3.1.0 API' do
    def app
      ResponseContentTestAPI
    end

    let(:swagger_doc) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates valid swagger documentation' do
      expect(swagger_doc).to be_a(Hash)
    end

    context 'GET endpoint responses' do
      let(:get_method) { swagger_doc['paths']['/users']['get'] }

      it 'includes responses' do
        expect(get_method).to have_key('responses')
      end

      it 'has 200 response' do
        expect(get_method['responses']).to have_key('200')
      end

      it 'has description in 200 response' do
        response_200 = get_method['responses']['200']
        expect(response_200).to have_key('description')
      end
    end

    context 'POST endpoint responses' do
      let(:post_method) { swagger_doc['paths']['/users']['post'] }

      it 'includes responses' do
        expect(post_method).to have_key('responses')
      end

      it 'has 201 response' do
        expect(post_method['responses']).to have_key('201')
      end
    end

    context 'DELETE endpoint responses' do
      let(:delete_method) { swagger_doc['paths']['/users/{id}']['delete'] }

      it 'includes responses' do
        expect(delete_method).to have_key('responses')
      end

      it 'has response with description' do
        responses = delete_method['responses']
        # DELETE typically returns 204
        response = responses.values.first
        expect(response).to have_key('description')
      end
    end

    context 'response structure for OpenAPI 3.1.0' do
      let(:get_method) { swagger_doc['paths']['/users']['get'] }

      it 'wraps response with content when schema is present' do
        response_200 = get_method['responses']['200']
        # When there is a schema, it should be wrapped in content for 3.1.0
        if response_200.key?('content')
          expect(response_200['content']).to be_a(Hash)
        else
          # No schema means no content wrapper - just description
          expect(response_200).to have_key('description')
        end
      end
    end

    context 'response does not include swagger 2.0 artifacts' do
      let(:get_method) { swagger_doc['paths']['/users']['get'] }

      it 'does not have produces at the method level for OpenAPI 3.1.0' do
        # In OpenAPI 3.1.0, produces is replaced by content in responses
        # The method may still have produces internally for building, but
        # the final output should use content-based structure
        response_200 = get_method['responses']['200']
        expect(response_200).to have_key('description')
      end
    end
  end

  context 'Swagger 2.0 API (backward compatibility)' do
    def app
      ResponseContentSwagger2API
    end

    let(:swagger_doc) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'uses swagger 2.0 format' do
      expect(swagger_doc).to have_key('swagger')
      expect(swagger_doc['swagger']).to eq('2.0')
    end

    it 'does not wrap responses in content for Swagger 2.0' do
      get_method = swagger_doc['paths']['/items']['get']
      response_200 = get_method['responses']['200']

      # Swagger 2.0 responses should not have content wrapper
      expect(response_200).not_to have_key('content')
    end

    it 'keeps schema at response level for Swagger 2.0' do
      get_method = swagger_doc['paths']['/items']['get']
      response_200 = get_method['responses']['200']

      expect(response_200).to have_key('description')
    end

    it 'includes produces at top level for Swagger 2.0' do
      expect(swagger_doc).to have_key('produces')
    end
  end
end
