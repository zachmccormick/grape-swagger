# frozen_string_literal: true

require 'spec_helper'

describe 'Parameter examples (OpenAPI 3.1.0)' do
  # ============================================
  # Single example
  # ============================================
  describe 'single example' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get user by ID'
        params do
          requires :id, type: Integer, documentation: {
            desc: 'User ID',
            example: 12_345
          }
        end
        get '/users/:id' do
          { id: params[:id] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes example in parameter (not x-example)' do
      params = subject['paths']['/users/{id}']['get']['parameters']
      id_param = params.find { |p| p['name'] == 'id' }
      expect(id_param['example']).to eq(12_345)
      expect(id_param).not_to have_key('x-example')
    end
  end

  # ============================================
  # Multiple named examples
  # ============================================
  describe 'multiple named examples' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Search users'
        params do
          optional :status, type: String, documentation: {
            desc: 'User status',
            examples: {
              active: {
                summary: 'Active user',
                value: 'active'
              },
              inactive: {
                summary: 'Inactive user',
                value: 'inactive'
              },
              pending: {
                summary: 'Pending approval',
                description: 'User awaiting admin approval',
                value: 'pending'
              }
            }
          }
        end
        get '/users' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes examples map in parameter' do
      params = subject['paths']['/users']['get']['parameters']
      status_param = params.find { |p| p['name'] == 'status' }
      expect(status_param['examples']).to be_a(Hash)
      expect(status_param['examples'].keys).to contain_exactly('active', 'inactive', 'pending')
    end

    it 'preserves example object structure' do
      params = subject['paths']['/users']['get']['parameters']
      status_param = params.find { |p| p['name'] == 'status' }

      expect(status_param['examples']['active']['summary']).to eq('Active user')
      expect(status_param['examples']['active']['value']).to eq('active')
      expect(status_param['examples']['pending']['description']).to eq('User awaiting admin approval')
    end
  end

  # ============================================
  # Example with external value
  # ============================================
  describe 'example with externalValue' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Upload config'
        params do
          optional :config, type: String, documentation: {
            desc: 'Configuration JSON',
            examples: {
              sample: {
                summary: 'Sample configuration',
                externalValue: 'https://example.com/config-sample.json'
              }
            }
          }
        end
        get '/config' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'preserves externalValue in examples' do
      params = subject['paths']['/config']['get']['parameters']
      config_param = params.find { |p| p['name'] == 'config' }
      expect(config_param['examples']['sample']['externalValue']).to eq('https://example.com/config-sample.json')
    end
  end

  # ============================================
  # Query parameter with example
  # ============================================
  describe 'query parameter with example' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Search items'
        params do
          optional :query, type: String, documentation: {
            desc: 'Search query',
            example: 'laptop'
          }
          optional :limit, type: Integer, documentation: {
            desc: 'Maximum results',
            example: 10
          }
        end
        get '/items' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes example for string parameter' do
      params = subject['paths']['/items']['get']['parameters']
      query_param = params.find { |p| p['name'] == 'query' }
      expect(query_param['example']).to eq('laptop')
    end

    it 'includes example for integer parameter' do
      params = subject['paths']['/items']['get']['parameters']
      limit_param = params.find { |p| p['name'] == 'limit' }
      expect(limit_param['example']).to eq(10)
    end
  end

  # ============================================
  # Swagger 2.0 compatibility
  # ============================================
  describe 'Swagger 2.0' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get user'
        params do
          requires :id, type: Integer, documentation: {
            example: 42
          }
        end
        get '/users/:id' do
          { id: params[:id] }
        end

        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'uses x-example for Swagger 2.0' do
      params = subject['paths']['/users/{id}']['get']['parameters']
      id_param = params.find { |p| p['name'] == 'id' }
      expect(id_param['x-example']).to eq(42)
      expect(id_param).not_to have_key('example')
    end
  end

  # ============================================
  # Array parameter example
  # ============================================
  describe 'array parameter example' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Filter by tags'
        params do
          optional :tags, type: Array[String], documentation: {
            desc: 'Tags to filter by',
            example: %w[electronics sale]
          }
        end
        get '/products' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes array example in parameter' do
      params = subject['paths']['/products']['get']['parameters']
      tags_param = params.find { |p| p['name'] == 'tags' }
      expect(tags_param['example']).to eq(%w[electronics sale])
    end
  end
end
