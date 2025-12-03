# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 Style Features' do
  describe 'Response examples' do
    include_context "#{MODEL_PARSER} swagger example"

    def app
      Class.new(Grape::API) do
        format :json

        desc 'This returns examples' do
          success model: Entities::UseResponse, examples: { 'application/json' => { description: 'Names list', items: [{ id: '123', name: 'John' }] } }
          failure [[404, 'NotFound', Entities::ApiError, { 'application/json' => { code: 404, message: 'Not found' } }]]
        end
        get '/with_examples' do
          { 'declared_params' => declared(params) }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates OpenAPI 3.1.0' do
      expect(subject['openapi']).to eq('3.1.0')
    end

    it 'includes example in 200 response' do
      response_200 = subject['paths']['/with_examples']['get']['responses']['200']
      expect(response_200).to have_key('content')
      json_content = response_200['content']['application/json']
      # OpenAPI 3.x uses 'example' (singular) for single examples
      expect(json_content).to have_key('example')
      expect(json_content['example']).to eq({
        'description' => 'Names list',
        'items' => [{ 'id' => '123', 'name' => 'John' }]
      })
    end

    it 'includes example in 404 response' do
      response_404 = subject['paths']['/with_examples']['get']['responses']['404']
      expect(response_404).to have_key('content')
      json_content = response_404['content']['application/json']
      # OpenAPI 3.x uses 'example' (singular) for single examples
      expect(json_content).to have_key('example')
      expect(json_content['example']).to eq({
        'code' => 404,
        'message' => 'Not found'
      })
    end
  end

  describe 'Operation summary' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get user details',
             summary: 'Retrieve a user by ID',
             detail: 'This endpoint returns detailed information about a specific user.'
        params do
          requires :id, type: Integer, desc: 'User ID'
        end
        get '/users/:id' do
          { id: params[:id], name: 'John' }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates OpenAPI 3.1.0' do
      expect(subject['openapi']).to eq('3.1.0')
    end

    it 'includes summary in operation' do
      operation = subject['paths']['/users/{id}']['get']
      expect(operation).to have_key('summary')
      expect(operation['summary']).to eq('Retrieve a user by ID')
    end

    it 'includes description in operation' do
      operation = subject['paths']['/users/{id}']['get']
      expect(operation).to have_key('description')
      expect(operation['description']).to eq('This endpoint returns detailed information about a specific user.')
    end
  end

  describe 'Minimum/maximum for integers' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items with pagination'
        params do
          requires :page, type: Integer, values: 1..100, desc: 'Page number'
          requires :per_page, type: Integer, values: 1..50, desc: 'Items per page'
          optional :offset, type: Integer, values: 0..1000, desc: 'Offset'
        end
        get '/items' do
          { page: params[:page], per_page: params[:per_page] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates OpenAPI 3.1.0' do
      expect(subject['openapi']).to eq('3.1.0')
    end

    it 'includes minimum and maximum for page parameter' do
      parameters = subject['paths']['/items']['get']['parameters']
      page_param = parameters.find { |p| p['name'] == 'page' }
      expect(page_param['schema']).to include('minimum' => 1)
      expect(page_param['schema']).to include('maximum' => 100)
    end

    it 'includes minimum and maximum for per_page parameter' do
      parameters = subject['paths']['/items']['get']['parameters']
      per_page_param = parameters.find { |p| p['name'] == 'per_page' }
      expect(per_page_param['schema']).to include('minimum' => 1)
      expect(per_page_param['schema']).to include('maximum' => 50)
    end

    it 'includes minimum and maximum for offset parameter' do
      parameters = subject['paths']['/items']['get']['parameters']
      offset_param = parameters.find { |p| p['name'] == 'offset' }
      expect(offset_param['schema']).to include('minimum' => 0)
      expect(offset_param['schema']).to include('maximum' => 1000)
    end
  end

  describe 'Schema description' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create a user'
        params do
          requires :name, type: String, desc: 'Full name of the user'
          requires :email, type: String, desc: 'Email address for contact'
          optional :age, type: Integer, desc: 'Age in years'
        end
        post '/users' do
          { id: 1 }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes description in requestBody schema properties' do
      request_body = subject['paths']['/users']['post']['requestBody']
      schema = request_body['content']['application/json']['schema']

      # The schema might be a $ref or inline - check for referenced schema
      if schema['$ref']
        schema_name = schema['$ref'].split('/').last
        actual_schema = subject['components']['schemas'][schema_name]
        expect(actual_schema['properties']['name']).to include('description' => 'Full name of the user')
        expect(actual_schema['properties']['email']).to include('description' => 'Email address for contact')
        expect(actual_schema['properties']['age']).to include('description' => 'Age in years')
      else
        # Inline schema
        expect(schema['properties']['name']).to include('description' => 'Full name of the user')
        expect(schema['properties']['email']).to include('description' => 'Email address for contact')
        expect(schema['properties']['age']).to include('description' => 'Age in years')
      end
    end
  end
end
