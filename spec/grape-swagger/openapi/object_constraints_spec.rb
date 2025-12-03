# frozen_string_literal: true

require 'spec_helper'

describe 'Schema minProperties and maxProperties (OpenAPI 3.1.0)' do
  # ============================================
  # Query Parameter with object constraints
  # ============================================
  describe 'query parameter with object constraints' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Search with filters'
        params do
          # Use JSON type for query params as Hash params become body params
          optional :filters, type: JSON, documentation: {
            min_properties: 1,
            max_properties: 5,
            desc: 'Filter object with 1-5 properties'
          }
        end
        get '/search' do
          { filters: params[:filters] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes minProperties in parameter schema' do
      params = subject['paths']['/search']['get']['parameters']
      filters_param = params.find { |p| p['name'] == 'filters' }
      expect(filters_param['schema']['minProperties']).to eq(1)
    end

    it 'includes maxProperties in parameter schema' do
      params = subject['paths']['/search']['get']['parameters']
      filters_param = params.find { |p| p['name'] == 'filters' }
      expect(filters_param['schema']['maxProperties']).to eq(5)
    end
  end

  # ============================================
  # Request Body with object constraints
  # ============================================
  describe 'request body with object constraints' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create metadata'
        params do
          requires :metadata, type: Hash, documentation: {
            min_properties: 2,
            max_properties: 10,
            desc: 'Metadata must have 2-10 properties'
          }
        end
        post '/items' do
          { metadata: params[:metadata] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes minProperties in request body schema' do
      schema_ref = subject['paths']['/items']['post']['requestBody']['content']['application/json']['schema']['$ref']
      schema_name = schema_ref.split('/').last
      schema = subject['components']['schemas'][schema_name]

      expect(schema['properties']['metadata']['minProperties']).to eq(2)
    end

    it 'includes maxProperties in request body schema' do
      schema_ref = subject['paths']['/items']['post']['requestBody']['content']['application/json']['schema']['$ref']
      schema_name = schema_ref.split('/').last
      schema = subject['components']['schemas'][schema_name]

      expect(schema['properties']['metadata']['maxProperties']).to eq(10)
    end
  end

  # ============================================
  # Only minProperties
  # ============================================
  describe 'with only minProperties' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get config'
        params do
          optional :config, type: JSON, documentation: {
            min_properties: 1,
            desc: 'Config must have at least 1 property'
          }
        end
        get '/config' do
          { config: params[:config] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes minProperties but not maxProperties' do
      params = subject['paths']['/config']['get']['parameters']
      config_param = params.find { |p| p['name'] == 'config' }
      expect(config_param['schema']['minProperties']).to eq(1)
      expect(config_param['schema']).not_to have_key('maxProperties')
    end
  end

  # ============================================
  # Only maxProperties
  # ============================================
  describe 'with only maxProperties' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get settings'
        params do
          optional :settings, type: JSON, documentation: {
            max_properties: 3,
            desc: 'Settings can have at most 3 properties'
          }
        end
        get '/settings' do
          { settings: params[:settings] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes maxProperties but not minProperties' do
      params = subject['paths']['/settings']['get']['parameters']
      settings_param = params.find { |p| p['name'] == 'settings' }
      expect(settings_param['schema']['maxProperties']).to eq(3)
      expect(settings_param['schema']).not_to have_key('minProperties')
    end
  end

  # ============================================
  # Swagger 2.0 compatibility
  # ============================================
  describe 'Swagger 2.0' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get data'
        params do
          optional :data, type: JSON, documentation: {
            min_properties: 1,
            max_properties: 5
          }
        end
        get '/data' do
          { data: params[:data] }
        end

        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes object constraints in Swagger 2.0 as well' do
      params = subject['paths']['/data']['get']['parameters']
      data_param = params.find { |p| p['name'] == 'data' }
      expect(data_param['minProperties']).to eq(1)
      expect(data_param['maxProperties']).to eq(5)
    end
  end

  # ============================================
  # Zero value handling
  # ============================================
  describe 'zero value handling' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Empty allowed'
        params do
          optional :empty_ok, type: JSON, documentation: {
            min_properties: 0
          }
        end
        get '/empty' do
          { empty_ok: params[:empty_ok] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes minProperties: 0' do
      params = subject['paths']['/empty']['get']['parameters']
      empty_param = params.find { |p| p['name'] == 'empty_ok' }
      expect(empty_param['schema']['minProperties']).to eq(0)
    end
  end
end
