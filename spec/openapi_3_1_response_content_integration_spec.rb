# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 ResponseContent Integration' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get items',
           success: [
             { code: 200, message: 'Success' },
             { code: 201, message: 'Created' }
           ],
           failure: [
             { code: 400, message: 'Bad Request' },
             { code: 404, message: 'Not Found' }
           ]
      params do
        optional :filter, type: String
      end
      get '/items' do
        { items: [] }
      end

      desc 'Create item',
           success: { code: 201, message: 'Created' }
      params do
        requires :name, type: String
      end
      post '/items' do
        { id: 1, name: params[:name] }
      end

      desc 'Delete item',
           success: { code: 204, message: 'No Content' }
      delete '/items/:id' do
        status 204
      end

      desc 'Get with examples',
           success: {
             code: 200,
             message: 'Success',
             examples: {
               'application/json' => { id: 1, name: 'Example' }
             }
           }
      get '/with-examples' do
        { id: 1, name: 'Example' }
      end

      add_swagger_documentation(
        openapi_version: '3.1.0',
        doc_version: '1.0.0',
        info: { title: 'Test API', version: '1.0.0' }
      )
    end
  end

  describe 'GET endpoint with responses' do
    subject(:spec) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates OpenAPI 3.1.0 spec' do
      expect(spec['openapi']).to eq('3.1.0')
    end

    it 'includes responses in GET operation' do
      operation = spec.dig('paths', '/items', 'get')
      expect(operation).to have_key('responses')
    end

    it 'preserves description at response level' do
      response = spec.dig('paths', '/items', 'get', 'responses', '200')
      expect(response).to have_key('description')
      expect(response['description']).to eq('Success')
    end
  end

  describe 'Multiple status codes' do
    subject(:spec) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'has multiple response codes defined' do
      responses = spec.dig('paths', '/items', 'get', 'responses')
      expect(responses).to have_key('200')
      expect(responses).to have_key('201')
      expect(responses).to have_key('400')
      expect(responses).to have_key('404')
    end
  end

  describe 'POST endpoint with responses' do
    subject(:spec) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes responses for POST operation' do
      operation = spec.dig('paths', '/items', 'post')
      expect(operation).to have_key('responses')
    end
  end

  describe 'DELETE endpoint with 204 No Content' do
    subject(:spec) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes description for 204 response' do
      response = spec.dig('paths', '/items/{id}', 'delete', 'responses', '204')
      expect(response).to have_key('description')
      expect(response['description']).to eq('No Content')
    end
  end

  describe 'Swagger 2.0 backward compatibility' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items',
             success: { code: 200, message: 'Success' }
        get '/items' do
          { items: [] }
        end

        add_swagger_documentation(
          doc_version: '1.0.0',
          info: { title: 'Test API', version: '1.0.0' }
        )
      end
    end

    subject(:spec) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates Swagger 2.0 spec by default' do
      expect(spec['swagger']).to eq('2.0')
    end

    it 'does not include content in responses for Swagger 2.0' do
      response = spec.dig('paths', '/items', 'get', 'responses', '200')
      expect(response).not_to have_key('content')
    end
  end

end
