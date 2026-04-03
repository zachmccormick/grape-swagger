# frozen_string_literal: true

require 'spec_helper'

describe 'Schema title and not Properties (OpenAPI 3.1.0)' do
  # ============================================
  # Schema `title` Property
  # ============================================
  describe 'Schema title property' do
    describe 'parameter-level title' do
      def app
        Class.new(Grape::API) do
          format :json

          desc 'Endpoint with titled parameters'
          params do
            requires :user_id, type: Integer, documentation: { title: 'User Identifier' }, desc: 'The unique user ID'
            optional :status, type: String, documentation: { title: 'Account Status' }, desc: 'Current account status'
          end
          get '/users/:user_id' do
            { id: params[:user_id] }
          end

          add_swagger_documentation openapi_version: '3.1.0'
        end
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'includes title in path parameter schema' do
        params = subject['paths']['/users/{user_id}']['get']['parameters']
        user_id_param = params.find { |p| p['name'] == 'user_id' }

        expect(user_id_param['schema']['title']).to eq('User Identifier')
      end

      it 'includes title in query parameter' do
        params = subject['paths']['/users/{user_id}']['get']['parameters']
        status_param = params.find { |p| p['name'] == 'status' }

        expect(status_param['schema']['title']).to eq('Account Status')
      end
    end

    describe 'request body property title' do
      def app
        Class.new(Grape::API) do
          format :json

          desc 'Create user with titled fields'
          params do
            requires :email, type: String, documentation: { title: 'Email Address' }
            requires :password, type: String, documentation: { title: 'Password', write_only: true }
            optional :nickname, type: String, documentation: { title: 'Display Name' }
          end
          post '/users' do
            { email: params[:email] }
          end

          add_swagger_documentation openapi_version: '3.1.0'
        end
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'includes title in request body schema properties' do
        request_body = subject['paths']['/users']['post']['requestBody']
        schema_ref = request_body['content']['application/json']['schema']['$ref']

        schema_name = schema_ref.split('/').last
        schema = subject['components']['schemas'][schema_name]

        expect(schema['properties']['email']['title']).to eq('Email Address')
        expect(schema['properties']['password']['title']).to eq('Password')
        expect(schema['properties']['nickname']['title']).to eq('Display Name')
      end
    end
  end

  # ============================================
  # Schema `not` Property
  # ============================================
  describe 'Schema not property' do
    describe 'inline not schema' do
      def app
        Class.new(Grape::API) do
          format :json

          desc 'Endpoint with not constraint'
          params do
            requires :value, type: String, documentation: {
              not: { type: 'string', enum: %w[forbidden blocked] },
              desc: 'Any value except forbidden or blocked'
            }
          end
          post '/validate' do
            { value: params[:value] }
          end

          add_swagger_documentation openapi_version: '3.1.0'
        end
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'includes not constraint in schema' do
        request_body = subject['paths']['/validate']['post']['requestBody']
        schema_ref = request_body['content']['application/json']['schema']['$ref']

        schema_name = schema_ref.split('/').last
        schema = subject['components']['schemas'][schema_name]
        value_schema = schema['properties']['value']

        expect(value_schema).to have_key('not')
        expect(value_schema['not']['type']).to eq('string')
        expect(value_schema['not']['enum']).to eq(%w[forbidden blocked])
      end
    end

    describe 'not with type constraint' do
      def app
        Class.new(Grape::API) do
          format :json

          desc 'Parameter that must not be null'
          params do
            requires :data, type: String, documentation: {
              not: { type: 'null' },
              desc: 'Data that cannot be null'
            }
          end
          post '/data' do
            { data: params[:data] }
          end

          add_swagger_documentation openapi_version: '3.1.0'
        end
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'includes not type constraint' do
        request_body = subject['paths']['/data']['post']['requestBody']
        schema_ref = request_body['content']['application/json']['schema']['$ref']

        schema_name = schema_ref.split('/').last
        schema = subject['components']['schemas'][schema_name]
        data_schema = schema['properties']['data']

        expect(data_schema['not']['type']).to eq('null')
      end
    end

    describe 'not with schema reference (string)' do
      def app
        Class.new(Grape::API) do
          format :json

          desc 'Parameter that must not match a schema'
          params do
            requires :config, type: Hash, documentation: {
              not: 'DeprecatedConfig',
              desc: 'Configuration that must not match deprecated schema'
            }
          end
          post '/settings' do
            { config: params[:config] }
          end

          add_swagger_documentation openapi_version: '3.1.0'
        end
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'includes not with $ref to schema' do
        request_body = subject['paths']['/settings']['post']['requestBody']
        schema_ref = request_body['content']['application/json']['schema']['$ref']

        schema_name = schema_ref.split('/').last
        schema = subject['components']['schemas'][schema_name]
        config_schema = schema['properties']['config']

        expect(config_schema['not']['$ref']).to eq('#/components/schemas/DeprecatedConfig')
      end
    end

    describe 'not with schema reference (symbol)' do
      def app
        Class.new(Grape::API) do
          format :json

          desc 'Parameter with symbol schema reference in not'
          params do
            requires :payload, type: Hash, documentation: {
              not: :InvalidPayload,
              desc: 'Payload must not match InvalidPayload schema'
            }
          end
          post '/process' do
            { payload: params[:payload] }
          end

          add_swagger_documentation openapi_version: '3.1.0'
        end
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'includes not with $ref from symbol' do
        request_body = subject['paths']['/process']['post']['requestBody']
        schema_ref = request_body['content']['application/json']['schema']['$ref']

        schema_name = schema_ref.split('/').last
        schema = subject['components']['schemas'][schema_name]
        payload_schema = schema['properties']['payload']

        expect(payload_schema['not']['$ref']).to eq('#/components/schemas/InvalidPayload')
      end
    end

    describe 'not with multiple constraints' do
      def app
        Class.new(Grape::API) do
          format :json

          desc 'Parameter with complex not constraint'
          params do
            requires :code, type: String, documentation: {
              not: {
                type: 'string',
                pattern: '^DEPRECATED_.*',
                minLength: 20
              },
              desc: 'Code that does not match deprecated pattern'
            }
          end
          post '/codes' do
            { code: params[:code] }
          end

          add_swagger_documentation openapi_version: '3.1.0'
        end
      end

      subject do
        get '/swagger_doc'
        JSON.parse(last_response.body)
      end

      it 'includes not with multiple constraints' do
        request_body = subject['paths']['/codes']['post']['requestBody']
        schema_ref = request_body['content']['application/json']['schema']['$ref']

        schema_name = schema_ref.split('/').last
        schema = subject['components']['schemas'][schema_name]
        code_schema = schema['properties']['code']

        expect(code_schema['not']['type']).to eq('string')
        expect(code_schema['not']['pattern']).to eq('^DEPRECATED_.*')
        expect(code_schema['not']['minLength']).to eq(20)
      end
    end
  end

  # ============================================
  # Combined title and not
  # ============================================
  describe 'combined title and not' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with both title and not'
        params do
          requires :username, type: String, documentation: {
            title: 'Username',
            not: { enum: %w[admin root system] },
            desc: 'User-chosen username (reserved names not allowed)'
          }
        end
        post '/register' do
          { username: params[:username] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes both title and not in schema' do
      request_body = subject['paths']['/register']['post']['requestBody']
      schema_ref = request_body['content']['application/json']['schema']['$ref']

      schema_name = schema_ref.split('/').last
      schema = subject['components']['schemas'][schema_name]
      username_schema = schema['properties']['username']

      expect(username_schema['title']).to eq('Username')
      expect(username_schema['not']['enum']).to eq(%w[admin root system])
      expect(username_schema['description']).to eq('User-chosen username (reserved names not allowed)')
    end
  end
end
