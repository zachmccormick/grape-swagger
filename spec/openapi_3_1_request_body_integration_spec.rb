# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 RequestBody Integration' do
  describe 'POST endpoint with requestBody support' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create a user',
             detail: 'Create a new user with the provided information'
        params do
          requires :name, type: String, desc: 'User name'
          requires :email, type: String, desc: 'User email'
          optional :age, type: Integer, desc: 'User age'
        end
        post '/users' do
          { id: 1, name: params[:name], email: params[:email] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates OpenAPI 3.1.0 spec' do
      expect(subject['openapi']).to eq('3.1.0')
    end

    it 'includes requestBody in POST operation' do
      post_operation = subject['paths']['/users']['post']
      expect(post_operation).to have_key('requestBody')
    end

    it 'requestBody has required field set' do
      post_operation = subject['paths']['/users']['post']
      expect(post_operation['requestBody']).to have_key('required')
    end

    it 'requestBody has content object' do
      post_operation = subject['paths']['/users']['post']
      expect(post_operation['requestBody']).to have_key('content')
    end

    it 'requestBody content includes application/json' do
      post_operation = subject['paths']['/users']['post']
      content = post_operation['requestBody']['content']
      expect(content).to have_key('application/json')
    end

    it 'requestBody application/json has schema' do
      post_operation = subject['paths']['/users']['post']
      schema = post_operation['requestBody']['content']['application/json']['schema']
      expect(schema).not_to be_nil
    end

    it 'does not include body parameters in parameters array for 3.1.0' do
      post_operation = subject['paths']['/users']['post']
      if post_operation.key?('parameters')
        body_params = post_operation['parameters'].select { |p| p['in'] == 'body' }
        expect(body_params).to be_empty
      end
    end
  end

  describe 'PUT endpoint with requestBody support' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Update a user'
        params do
          requires :id, type: Integer, desc: 'User ID'
          requires :name, type: String, desc: 'User name'
        end
        put '/users/:id' do
          { id: params[:id], name: params[:name] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes requestBody in PUT operation' do
      put_operation = subject['paths']['/users/{id}']['put']
      expect(put_operation).to have_key('requestBody')
    end

    it 'requestBody content includes application/json' do
      put_operation = subject['paths']['/users/{id}']['put']
      expect(put_operation['requestBody']['content']).to have_key('application/json')
    end
  end

  describe 'PATCH endpoint with requestBody support' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Partially update a user'
        params do
          requires :id, type: Integer, desc: 'User ID'
          optional :name, type: String, desc: 'User name'
          optional :email, type: String, desc: 'User email'
        end
        patch '/users/:id' do
          { id: params[:id] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes requestBody in PATCH operation' do
      patch_operation = subject['paths']['/users/{id}']['patch']
      expect(patch_operation).to have_key('requestBody')
    end
  end

  describe 'GET endpoint should not have requestBody' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get a user'
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

    it 'does not include requestBody in GET operation' do
      get_operation = subject['paths']['/users/{id}']['get']
      expect(get_operation).not_to have_key('requestBody')
    end
  end

  describe 'Swagger 2.0 backward compatibility' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create a user'
        params do
          requires :name, type: String, desc: 'User name'
        end
        post '/users' do
          { id: 1, name: params[:name] }
        end

        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates Swagger 2.0 spec by default' do
      expect(subject['swagger']).to eq('2.0')
    end

    it 'does not include requestBody in Swagger 2.0' do
      post_operation = subject['paths']['/users']['post']
      expect(post_operation).not_to have_key('requestBody')
    end

    it 'includes body parameters in parameters array for Swagger 2.0' do
      post_operation = subject['paths']['/users']['post']
      expect(post_operation).to have_key('parameters')
      parameters = post_operation['parameters']
      expect(parameters).not_to be_empty
    end
  end

  describe 'Multiple content types support' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create a user with XML support',
             consumes: ['application/json', 'application/xml']
        params do
          requires :name, type: String, desc: 'User name'
        end
        post '/users' do
          { id: 1, name: params[:name] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes multiple content types in requestBody' do
      post_operation = subject['paths']['/users']['post']
      content = post_operation['requestBody']['content']
      expect(content).to have_key('application/json')
      expect(content).to have_key('application/xml')
    end

    it 'each content type has a schema' do
      post_operation = subject['paths']['/users']['post']
      content = post_operation['requestBody']['content']
      expect(content['application/json']).to have_key('schema')
      expect(content['application/xml']).to have_key('schema')
    end
  end

  describe 'Required and optional body parameters' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create a user with optional fields'
        params do
          requires :name, type: String, desc: 'User name'
          optional :email, type: String, desc: 'User email'
        end
        post '/users' do
          { id: 1, name: params[:name] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'sets requestBody required to true when required params exist' do
      post_operation = subject['paths']['/users']['post']
      expect(post_operation['requestBody']['required']).to be true
    end
  end

  describe 'Schema generation for requestBody' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create a user'
        params do
          requires :name, type: String, desc: 'User name'
          requires :email, type: String, desc: 'User email'
          optional :age, type: Integer, desc: 'User age'
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

    it 'references a schema with $ref' do
      post_operation = subject['paths']['/users']['post']
      schema = post_operation['requestBody']['content']['application/json']['schema']
      expect(schema).to have_key('$ref')
      expect(schema['$ref']).to start_with('#/components/schemas/')
    end

    it 'referenced schema has type object and properties' do
      post_operation = subject['paths']['/users']['post']
      schema = post_operation['requestBody']['content']['application/json']['schema']
      schema_name = schema['$ref'].split('/').last
      referenced_schema = subject['components']['schemas'][schema_name]
      expect(referenced_schema['type']).to eq('object')
      expect(referenced_schema).to have_key('properties')
      expect(referenced_schema['properties']).to have_key('name')
      expect(referenced_schema['properties']).to have_key('email')
      expect(referenced_schema['properties']).to have_key('age')
    end
  end
end
