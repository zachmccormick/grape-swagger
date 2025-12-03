# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 Advanced Features' do
  # ============================================
  # Cookie Parameters
  # ============================================
  describe 'Cookie Parameters' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Session endpoint with cookie params'
        params do
          requires :session_id, type: String, documentation: { in: 'cookie' }, desc: 'Session ID'
          optional :csrf_token, type: String, documentation: { in: 'cookie' }, desc: 'CSRF token'
        end
        get '/session' do
          { session_id: params[:session_id] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes cookie parameters with in: cookie' do
      params = subject['paths']['/session']['get']['parameters']
      session_param = params.find { |p| p['name'] == 'session_id' }

      expect(session_param['in']).to eq('cookie')
    end

    it 'wraps cookie parameter type in schema object' do
      params = subject['paths']['/session']['get']['parameters']
      session_param = params.find { |p| p['name'] == 'session_id' }

      expect(session_param).to have_key('schema')
      expect(session_param['schema']['type']).to eq('string')
    end

    it 'includes style: form for cookie parameters' do
      params = subject['paths']['/session']['get']['parameters']
      session_param = params.find { |p| p['name'] == 'session_id' }

      expect(session_param['style']).to eq('form')
    end
  end

  # ============================================
  # Deprecated Parameters
  # ============================================
  describe 'Deprecated Parameters' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Search with deprecated parameter'
        params do
          optional :query, type: String, desc: 'Search query (preferred)'
          optional :q, type: String, documentation: { deprecated: true }, desc: 'Deprecated search param'
        end
        get '/search' do
          { query: params[:query] || params[:q] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'marks deprecated parameters with deprecated: true' do
      params = subject['paths']['/search']['get']['parameters']
      q_param = params.find { |p| p['name'] == 'q' }

      expect(q_param['deprecated']).to eq(true)
    end

    it 'does not mark non-deprecated parameters as deprecated' do
      params = subject['paths']['/search']['get']['parameters']
      query_param = params.find { |p| p['name'] == 'query' }

      expect(query_param).not_to have_key('deprecated')
    end
  end

  # ============================================
  # readOnly and writeOnly Schema Properties
  # ============================================
  describe 'readOnly and writeOnly Properties' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get user'
        params do
          requires :id, type: Integer, documentation: { read_only: true }, desc: 'User ID (read-only)'
        end
        get '/users/:id' do
          { id: params[:id] }
        end

        desc 'Create user'
        params do
          requires :username, type: String
          requires :password, type: String, documentation: { write_only: true }, desc: 'Password (write-only)'
        end
        post '/users' do
          { username: params[:username] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes readOnly in parameter schema' do
      params = subject['paths']['/users/{id}']['get']['parameters']
      id_param = params.find { |p| p['name'] == 'id' }

      expect(id_param['schema']['readOnly']).to eq(true)
    end

    it 'includes writeOnly in request body schema' do
      # The request body references a schema in components
      schema_ref = subject['paths']['/users']['post']['requestBody']['content']['application/json']['schema']['$ref']
      schema_name = schema_ref.split('/').last

      # Check the schema in components
      schema = subject['components']['schemas'][schema_name]
      properties = schema['properties']

      expect(properties['password']['writeOnly']).to eq(true)
    end
  end

  # ============================================
  # Operation-level External Documentation
  # ============================================
  describe 'Operation External Documentation' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Complex algorithm',
             external_docs: {
               description: 'Algorithm documentation',
               url: 'https://example.com/docs/algorithm'
             }
        get '/calculate' do
          { result: 42 }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes externalDocs at operation level' do
      operation = subject['paths']['/calculate']['get']

      expect(operation).to have_key('externalDocs')
      expect(operation['externalDocs']['description']).to eq('Algorithm documentation')
      expect(operation['externalDocs']['url']).to eq('https://example.com/docs/algorithm')
    end
  end

  # ============================================
  # Response Default Wildcard
  # ============================================
  describe 'Response Default Wildcard' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with default response',
             success: { code: 200, message: 'Success' },
             failure: [
               { code: 400, message: 'Bad request' },
               { code: 'default', message: 'Unexpected error' }
             ]
        get '/resource' do
          { id: 1 }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes default response in responses' do
      responses = subject['paths']['/resource']['get']['responses']

      expect(responses).to have_key('default')
      expect(responses['default']['description']).to eq('Unexpected error')
    end

    it 'includes other specific response codes' do
      responses = subject['paths']['/resource']['get']['responses']

      expect(responses).to have_key('200')
      expect(responses).to have_key('400')
    end
  end

  # ============================================
  # Callbacks
  # ============================================
  describe 'Callbacks' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Async job with callback',
             callbacks: {
               jobComplete: {
                 url: '{$request.body#/callback_url}',
                 method: :post,
                 summary: 'Job completed',
                 description: 'Called when job finishes',
                 request: {
                   schema: {
                     type: 'object',
                     properties: {
                       job_id: { type: 'string' },
                       status: { type: 'string', enum: %w[completed failed] }
                     }
                   }
                 },
                 responses: {
                   200 => { description: 'Callback received' }
                 }
               }
             }
        params do
          requires :callback_url, type: String
        end
        post '/jobs' do
          { job_id: 'job_123' }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes callbacks in operation' do
      operation = subject['paths']['/jobs']['post']

      expect(operation).to have_key('callbacks')
      expect(operation['callbacks']).to have_key('jobComplete')
    end

    it 'builds callback with URL expression' do
      callback = subject['paths']['/jobs']['post']['callbacks']['jobComplete']

      expect(callback).to have_key('{$request.body#/callback_url}')
    end

    it 'includes callback operation with requestBody' do
      callback = subject['paths']['/jobs']['post']['callbacks']['jobComplete']
      callback_op = callback['{$request.body#/callback_url}']['post']

      expect(callback_op).to have_key('summary')
      expect(callback_op).to have_key('requestBody')
      expect(callback_op).to have_key('responses')
    end
  end

  # ============================================
  # Links
  # ============================================
  describe 'Links' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create task with links',
             links: {
               200 => {
                 GetTaskById: {
                   operation_id: 'getTask',
                   parameters: { id: '$response.body#/id' },
                   description: 'Get the created task'
                 }
               }
             },
             success: { code: 200, message: 'Task created' }
        params do
          requires :title, type: String
        end
        post '/tasks' do
          { id: 123, title: params[:title] }
        end

        desc 'Get task by ID',
             operation_id: 'getTask'
        params do
          requires :id, type: Integer
        end
        get '/tasks/:id' do
          { id: params[:id] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes links in response' do
      response = subject['paths']['/tasks']['post']['responses']['200']

      expect(response).to have_key('links')
      expect(response['links']).to have_key('GetTaskById')
    end

    it 'builds link with operationId' do
      link = subject['paths']['/tasks']['post']['responses']['200']['links']['GetTaskById']

      expect(link['operationId']).to eq('getTask')
    end

    it 'includes link parameters' do
      link = subject['paths']['/tasks']['post']['responses']['200']['links']['GetTaskById']

      expect(link['parameters']).to eq({ 'id' => '$response.body#/id' })
    end

    it 'includes link description' do
      link = subject['paths']['/tasks']['post']['responses']['200']['links']['GetTaskById']

      expect(link['description']).to eq('Get the created task')
    end
  end

  # ============================================
  # Combined Features
  # ============================================
  describe 'Multiple Advanced Features Combined' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Advanced endpoint',
             external_docs: {
               description: 'Full docs',
               url: 'https://example.com/docs'
             },
             links: {
               200 => {
                 NextResource: { operation_id: 'getNext' }
               }
             },
             callbacks: {
               onComplete: {
                 url: '{$request.body#/webhook}',
                 request: { schema: { type: 'object' } },
                 responses: { 200 => { description: 'OK' } }
               }
             },
             success: { code: 200, message: 'Success' },
             failure: [
               { code: 400, message: 'Bad request' },
               { code: 'default', message: 'Error' }
             ]
        params do
          requires :id, type: Integer, documentation: { read_only: true }
          optional :legacy_id, type: Integer, documentation: { deprecated: true }
          optional :session, type: String, documentation: { in: 'cookie' }
        end
        get '/advanced/:id' do
          { id: params[:id] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes all advanced features together' do
      operation = subject['paths']['/advanced/{id}']['get']

      # External docs
      expect(operation).to have_key('externalDocs')

      # Callbacks
      expect(operation).to have_key('callbacks')

      # Links in response
      expect(operation['responses']['200']).to have_key('links')

      # Default response
      expect(operation['responses']).to have_key('default')

      # Cookie parameter
      params = operation['parameters']
      session_param = params.find { |p| p['name'] == 'session' }
      expect(session_param['in']).to eq('cookie')

      # Deprecated parameter
      legacy_param = params.find { |p| p['name'] == 'legacy_id' }
      expect(legacy_param['deprecated']).to eq(true)

      # readOnly in schema
      id_param = params.find { |p| p['name'] == 'id' }
      expect(id_param['schema']['readOnly']).to eq(true)
    end
  end
end
