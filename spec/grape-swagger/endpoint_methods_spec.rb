# frozen_string_literal: true

require 'spec_helper'

describe Grape::Endpoint do
  include Rack::Test::Methods

  describe 'wildcard status codes' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with wildcard status codes',
             http_codes: [
               { code: '2XX', message: 'Success response' },
               { code: '4XX', message: 'Client error' },
               { code: '5XX', message: 'Server error' }
             ]
        get '/wildcard' do
          { status: 'ok' }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    it 'includes wildcard status codes in responses' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      responses = result['paths']['/wildcard']['get']['responses']
      expect(responses).to have_key('2XX')
      expect(responses).to have_key('4XX')
      expect(responses).to have_key('5XX')
    end
  end

  describe 'transform_security_definitions' do
    def app
      Class.new(Grape::API) do
        format :json

        get '/test' do
          { status: 'ok' }
        end

        add_swagger_documentation(
          security_definitions: {
            api_key: { type: 'apiKey', name: 'api_key', in: 'query' },
            bearer: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }
          }
        )
      end
    end

    it 'transforms security definitions for Swagger 2.0' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      expect(result['securityDefinitions']).to be_a(Hash)
      expect(result['securityDefinitions']['api_key']).to eq({
        'type' => 'apiKey',
        'name' => 'api_key',
        'in' => 'query'
      })
    end
  end

  describe 'default_response' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with default response',
             default_response: { message: 'Default error response' }
        get '/with_default' do
          { status: 'ok' }
        end

        desc 'Endpoint with default response message only',
             default_response: { message: 'Fallback response' }
        get '/with_default_message' do
          { status: 'ok' }
        end

        add_swagger_documentation
      end
    end

    it 'includes default response in swagger doc' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      responses = result['paths']['/with_default']['get']['responses']
      expect(responses).to have_key('default')
      expect(responses['default']['description']).to eq('Default error response')
    end

    it 'handles default response with message only' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      responses = result['paths']['/with_default_message']['get']['responses']
      expect(responses).to have_key('default')
      expect(responses['default']['description']).to eq('Fallback response')
    end
  end

  describe 'file response handling' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Download file',
             success: 'file',
             produces: ['application/octet-stream']
        get '/download' do
          content_type 'application/octet-stream'
          'file contents'
        end

        desc 'Auto file response',
             success: 'file'
        get '/auto_download' do
          content_type 'application/octet-stream'
          'file contents'
        end

        add_swagger_documentation
      end
    end

    it 'uses file schema for file responses' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      response = result['paths']['/download']['get']['responses']['200']
      expect(response['schema']['type']).to eq('file')
    end

    it 'automatically sets octet-stream for file without explicit produces' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      produces = result['paths']['/auto_download']['get']['produces']
      expect(produces).to include('application/octet-stream')
    end
  end

  describe 'hidden parameter' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with hidden param'
        params do
          requires :visible_param, type: String
          optional :hidden_param, type: String, documentation: { hidden: true }
          optional :conditionally_hidden, type: String, documentation: { hidden: -> { true } }
        end
        get '/with_hidden_params' do
          { status: 'ok' }
        end

        add_swagger_documentation
      end
    end

    it 'excludes hidden parameters from documentation' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      params = result['paths']['/with_hidden_params']['get']['parameters']
      param_names = params.map { |p| p['name'] }

      expect(param_names).to include('visible_param')
      expect(param_names).not_to include('hidden_param')
      expect(param_names).not_to include('conditionally_hidden')
    end
  end

  describe 'external docs' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with external docs',
             external_docs: {
               description: 'Find more info here',
               url: 'https://example.com/docs'
             }
        get '/with_external_docs' do
          { status: 'ok' }
        end

        add_swagger_documentation
      end
    end

    it 'includes external docs in operation' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      external_docs = result['paths']['/with_external_docs']['get']['externalDocs']
      expect(external_docs['description']).to eq('Find more info here')
      expect(external_docs['url']).to eq('https://example.com/docs')
    end
  end

  describe 'deprecated endpoint' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Deprecated endpoint',
             deprecated: true
        get '/deprecated' do
          { status: 'ok' }
        end

        add_swagger_documentation
      end
    end

    it 'marks endpoint as deprecated' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      deprecated = result['paths']['/deprecated']['get']['deprecated']
      expect(deprecated).to be true
    end
  end

  describe 'delete response code handling' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Delete resource'
        delete '/resources/:id' do
          status 204
        end

        add_swagger_documentation
      end
    end

    it 'converts 200 to 204 for DELETE operations without model' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      responses = result['paths']['/resources/{id}']['delete']['responses']
      expect(responses).to have_key('204')
      expect(responses).not_to have_key('200')
    end
  end

  describe 'response with type parameter' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with typed response',
             http_codes: [
               { code: 200, message: 'Success', type: 'String' },
               { code: 201, message: 'Created', type: 'Integer', as: :id }
             ]
        post '/typed' do
          { id: 1 }
        end

        add_swagger_documentation
      end
    end

    it 'handles type parameter in response' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      response_200 = result['paths']['/typed']['post']['responses']['200']
      expect(response_200['schema']['type']).to eq('string')

      response_201 = result['paths']['/typed']['post']['responses']['201']
      expect(response_201['schema']['properties']['id']['type']).to eq('integer')
    end
  end

  describe 'summary and description' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'This is the description',
             detail: 'This is the detailed description',
             summary: 'This is the summary'
        get '/full' do
          { status: 'ok' }
        end

        desc 'Description when detail present',
             detail: 'Detailed description here'
        get '/with_detail' do
          { status: 'ok' }
        end

        add_swagger_documentation
      end
    end

    it 'uses summary option for summary' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      operation = result['paths']['/full']['get']
      expect(operation['summary']).to eq('This is the summary')
      expect(operation['description']).to eq('This is the detailed description')
    end

    it 'uses desc for summary when detail is present' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      operation = result['paths']['/with_detail']['get']
      # When detail is present, desc becomes summary
      expect(operation['summary']).to eq('Description when detail present')
      expect(operation['description']).to eq('Detailed description here')
    end
  end

  describe 'content types from target class' do
    def app
      Class.new(Grape::API) do
        content_type :json, 'application/json'
        content_type :xml, 'application/xml'
        format :json

        get '/test' do
          { status: 'ok' }
        end

        add_swagger_documentation
      end
    end

    it 'collects content types from target class' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      produces = result['produces']
      expect(produces).to include('application/json')
      expect(produces).to include('application/xml')
    end
  end

  describe 'operation-level servers' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with custom servers',
             servers: [
               { url: 'https://custom.example.com', description: 'Custom server' }
             ]
        get '/custom_server' do
          { status: 'ok' }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    it 'includes servers in operation' do
      get '/swagger_doc'
      result = JSON.parse(last_response.body)

      servers = result['paths']['/custom_server']['get']['servers']
      expect(servers).to be_a(Array)
      expect(servers.first['url']).to eq('https://custom.example.com')
    end
  end
end
