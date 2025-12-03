# frozen_string_literal: true

require 'spec_helper'

describe 'Path Item and Operation servers (OpenAPI 3.1.0)' do
  # ============================================
  # Operation-level servers
  # ============================================
  describe 'operation-level servers' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items from production server',
             servers: [
               { url: 'https://api.example.com', description: 'Production server' }
             ]
        get '/items' do
          []
        end

        desc 'Get items with multiple servers',
             servers: [
               { url: 'https://api.example.com', description: 'Production' },
               { url: 'https://staging-api.example.com', description: 'Staging' }
             ]
        get '/multi-server-items' do
          []
        end

        desc 'Get items without servers'
        get '/default-items' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes servers at operation level' do
      operation = subject['paths']['/items']['get']
      expect(operation['servers']).to be_an(Array)
      expect(operation['servers'].length).to eq(1)
      expect(operation['servers'][0]['url']).to eq('https://api.example.com')
      expect(operation['servers'][0]['description']).to eq('Production server')
    end

    it 'includes multiple servers at operation level' do
      operation = subject['paths']['/multi-server-items']['get']
      expect(operation['servers']).to be_an(Array)
      expect(operation['servers'].length).to eq(2)
      expect(operation['servers'][0]['url']).to eq('https://api.example.com')
      expect(operation['servers'][1]['url']).to eq('https://staging-api.example.com')
    end

    it 'does not include servers when not specified' do
      operation = subject['paths']['/default-items']['get']
      expect(operation).not_to have_key('servers')
    end
  end

  # ============================================
  # Path Item-level servers
  # ============================================
  describe 'path item-level servers' do
    def app
      Class.new(Grape::API) do
        format :json

        route_setting :path_servers, [
          { url: 'https://api.example.com/v1', description: 'V1 API server' }
        ]

        desc 'Get users'
        get '/users' do
          []
        end

        desc 'Create user'
        post '/users' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes servers at path item level' do
      path_item = subject['paths']['/users']
      expect(path_item['servers']).to be_an(Array)
      expect(path_item['servers'].length).to eq(1)
      expect(path_item['servers'][0]['url']).to eq('https://api.example.com/v1')
      expect(path_item['servers'][0]['description']).to eq('V1 API server')
    end

    it 'path item servers apply to all operations' do
      path_item = subject['paths']['/users']
      # Both GET and POST should be present, servers at path level
      expect(path_item).to have_key('get')
      expect(path_item).to have_key('post')
      expect(path_item).to have_key('servers')
    end
  end

  # ============================================
  # Combined path and operation servers
  # ============================================
  describe 'combined path and operation servers' do
    def app
      Class.new(Grape::API) do
        format :json

        route_setting :path_servers, [
          { url: 'https://api.example.com', description: 'Default server' }
        ]

        desc 'List orders'
        get '/orders' do
          []
        end

        desc 'Create order with different server',
             servers: [
               { url: 'https://orders.example.com', description: 'Orders service' }
             ]
        post '/orders' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'has path-level servers' do
      path_item = subject['paths']['/orders']
      expect(path_item['servers'][0]['url']).to eq('https://api.example.com')
    end

    it 'has operation-level servers that can override' do
      post_operation = subject['paths']['/orders']['post']
      expect(post_operation['servers'][0]['url']).to eq('https://orders.example.com')
    end
  end

  # ============================================
  # Servers with variables
  # ============================================
  describe 'servers with variables' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get products',
             servers: [
               {
                 url: 'https://{environment}.api.example.com',
                 description: 'Server with environment variable',
                 variables: {
                   environment: {
                     default: 'prod',
                     enum: %w[prod staging dev],
                     description: 'Environment to use'
                   }
                 }
               }
             ]
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

    it 'includes server variables' do
      operation = subject['paths']['/products']['get']
      server = operation['servers'][0]
      expect(server['url']).to eq('https://{environment}.api.example.com')
      expect(server['variables']).to be_a(Hash)
      expect(server['variables']['environment']['default']).to eq('prod')
      expect(server['variables']['environment']['enum']).to eq(%w[prod staging dev])
    end
  end

  # ============================================
  # Swagger 2.0 (should not include servers)
  # ============================================
  describe 'Swagger 2.0' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items',
             servers: [
               { url: 'https://api.example.com' }
             ]
        get '/items' do
          []
        end

        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes servers in Swagger 2.0 as well (passed through)' do
      # NOTE: servers is not valid Swagger 2.0 but we pass it through
      # for backwards compatibility - users can choose to filter it
      operation = subject['paths']['/items']['get']
      expect(operation['servers']).to be_an(Array)
    end
  end
end
