# frozen_string_literal: true

require 'spec_helper'

describe 'Schema externalDocs (OpenAPI 3.1.0)' do
  # ============================================
  # Query parameter with externalDocs
  # ============================================
  describe 'query parameter with externalDocs' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Search items'
        params do
          optional :query, type: String, documentation: {
            desc: 'Search query',
            external_docs: {
              url: 'https://docs.example.com/search-syntax',
              description: 'Search query syntax documentation'
            }
          }
        end
        get '/search' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes externalDocs in parameter schema' do
      params = subject['paths']['/search']['get']['parameters']
      query_param = params.find { |p| p['name'] == 'query' }
      expect(query_param['schema']['externalDocs']).to be_a(Hash)
      expect(query_param['schema']['externalDocs']['url']).to eq('https://docs.example.com/search-syntax')
      expect(query_param['schema']['externalDocs']['description']).to eq('Search query syntax documentation')
    end
  end

  # ============================================
  # Request body property with externalDocs
  # ============================================
  describe 'request body with externalDocs' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create item'
        params do
          requires :config, type: String, documentation: {
            desc: 'Configuration JSON',
            external_docs: {
              url: 'https://docs.example.com/config-schema',
              description: 'Full configuration documentation'
            }
          }
        end
        post '/items' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes externalDocs in request body schema property' do
      schema_ref = subject['paths']['/items']['post']['requestBody']['content']['application/json']['schema']['$ref']
      schema_name = schema_ref.split('/').last
      schema = subject['components']['schemas'][schema_name]

      expect(schema['properties']['config']['externalDocs']).to be_a(Hash)
      expect(schema['properties']['config']['externalDocs']['url']).to eq('https://docs.example.com/config-schema')
    end
  end

  # ============================================
  # URL-only shorthand
  # ============================================
  describe 'URL-only shorthand' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get data'
        params do
          optional :format, type: String, documentation: {
            desc: 'Output format',
            external_docs: 'https://docs.example.com/formats'
          }
        end
        get '/data' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'converts URL string to externalDocs object' do
      params = subject['paths']['/data']['get']['parameters']
      format_param = params.find { |p| p['name'] == 'format' }
      expect(format_param['schema']['externalDocs']).to be_a(Hash)
      expect(format_param['schema']['externalDocs']['url']).to eq('https://docs.example.com/formats')
    end
  end

  # ============================================
  # Multiple parameters with externalDocs
  # ============================================
  describe 'multiple parameters with externalDocs' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Advanced search'
        params do
          optional :query, type: String, documentation: {
            external_docs: {
              url: 'https://docs.example.com/query',
              description: 'Query language docs'
            }
          }
          optional :filter, type: String, documentation: {
            external_docs: {
              url: 'https://docs.example.com/filters',
              description: 'Filter syntax docs'
            }
          }
        end
        get '/advanced-search' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes externalDocs for each parameter' do
      params = subject['paths']['/advanced-search']['get']['parameters']
      query_param = params.find { |p| p['name'] == 'query' }
      filter_param = params.find { |p| p['name'] == 'filter' }

      expect(query_param['schema']['externalDocs']['url']).to eq('https://docs.example.com/query')
      expect(filter_param['schema']['externalDocs']['url']).to eq('https://docs.example.com/filters')
    end
  end

  # ============================================
  # Parameter without externalDocs
  # ============================================
  describe 'parameter without externalDocs' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Simple endpoint'
        params do
          optional :name, type: String, desc: 'A name'
        end
        get '/simple' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'does not include externalDocs when not specified' do
      params = subject['paths']['/simple']['get']['parameters']
      name_param = params.find { |p| p['name'] == 'name' }
      expect(name_param['schema']).not_to have_key('externalDocs')
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
          optional :query, type: String, documentation: {
            external_docs: {
              url: 'https://docs.example.com/query'
            }
          }
        end
        get '/data' do
          {}
        end

        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes externalDocs in Swagger 2.0 parameter' do
      params = subject['paths']['/data']['get']['parameters']
      query_param = params.find { |p| p['name'] == 'query' }
      # In Swagger 2.0, externalDocs stays at parameter level
      expect(query_param['externalDocs']).to be_a(Hash)
      expect(query_param['externalDocs']['url']).to eq('https://docs.example.com/query')
    end
  end
end
