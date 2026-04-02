# frozen_string_literal: true

require 'spec_helper'

describe 'Path-Level Parameters' do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  describe 'path_params DSL' do
    let(:app) do
      Class.new(Grape::API) do
        namespace :users do
          route_param :user_id, type: Integer, desc: 'User ID' do
            path_params :user_id # Mark as path-level parameter

            get do
              { user_id: params[:user_id] }
            end

            put do
              { user_id: params[:user_id] }
            end
          end
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'places parameters at path level, not duplicated per operation' do
      path_item = subject['paths']['/users/{user_id}']

      # Parameters should be at path level
      expect(path_item['parameters']).to be_an(Array)
      expect(path_item['parameters'].length).to eq(1)

      param = path_item['parameters'].first
      expect(param['name']).to eq('user_id')
      expect(param['in']).to eq('path')
      expect(param['required']).to eq(true)

      # GET and PUT should NOT have the user_id parameter duplicated
      expect(path_item['get']['parameters']).to be_nil
      expect(path_item['put']['parameters']).to be_nil
    end
  end

  describe 'nested path_params DSL' do
    let(:app) do
      Class.new(Grape::API) do
        namespace :users do
          route_param :user_id, type: Integer, desc: 'User ID' do
            namespace :posts do
              route_param :post_id, type: Integer, desc: 'Post ID' do
                path_params :user_id, :post_id # Mark both as path-level

                get do
                  { user_id: params[:user_id], post_id: params[:post_id] }
                end

                delete do
                  { deleted: true }
                end
              end
            end
          end
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'places multiple parameters at path level for nested routes' do
      path_item = subject['paths']['/users/{user_id}/posts/{post_id}']

      # Both user_id and post_id should be at path level
      expect(path_item['parameters']).to be_an(Array)
      expect(path_item['parameters'].length).to eq(2)

      param_names = path_item['parameters'].map { |p| p['name'] }
      expect(param_names).to include('user_id')
      expect(param_names).to include('post_id')

      # All parameters should be marked as path params
      path_item['parameters'].each do |param|
        expect(param['in']).to eq('path')
        expect(param['required']).to eq(true)
      end

      # GET and DELETE should NOT have parameters duplicated
      expect(path_item['get']['parameters']).to be_nil
      expect(path_item['delete']['parameters']).to be_nil
    end
  end

  describe 'path_servers route setting' do
    let(:app) do
      Class.new(Grape::API) do
        namespace :legacy do
          route_setting :path_servers, [{ url: 'https://legacy.example.com' }]

          get do
            { legacy: true }
          end
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'adds servers at the path level' do
      path_item = subject['paths']['/legacy']

      expect(path_item['servers']).to be_an(Array)
      expect(path_item['servers'].length).to eq(1)
      expect(path_item['servers'].first['url']).to eq('https://legacy.example.com')
    end
  end

  describe 'operation-level servers' do
    let(:app) do
      Class.new(Grape::API) do
        desc 'Get users', servers: [{ url: 'https://api2.example.com', description: 'Alt server' }]
        get :users do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'adds servers at the operation level' do
      operation = subject['paths']['/users']['get']

      expect(operation['servers']).to be_an(Array)
      expect(operation['servers'].length).to eq(1)
      expect(operation['servers'].first['url']).to eq('https://api2.example.com')
      expect(operation['servers'].first['description']).to eq('Alt server')
    end
  end

  describe 'without path_params DSL (no path-level extraction)' do
    let(:app) do
      Class.new(Grape::API) do
        namespace :users do
          route_param :user_id, type: Integer, desc: 'User ID' do
            get do
              { user_id: params[:user_id] }
            end

            put do
              { user_id: params[:user_id] }
            end
          end
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'keeps parameters at operation level when path_params is not used' do
      path_item = subject['paths']['/users/{user_id}']

      # No path-level parameters
      expect(path_item['parameters']).to be_nil

      # Each operation should have user_id parameter
      expect(path_item['get']['parameters']).to be_an(Array)
      user_id_param = path_item['get']['parameters'].find { |p| p['name'] == 'user_id' }
      expect(user_id_param).not_to be_nil
      expect(user_id_param['in']).to eq('path')

      expect(path_item['put']['parameters']).to be_an(Array)
      user_id_param = path_item['put']['parameters'].find { |p| p['name'] == 'user_id' }
      expect(user_id_param).not_to be_nil
    end
  end

  describe 'collect_path_param_names helper' do
    let(:endpoint) { Grape::Endpoint.new(Grape::Util::InheritableSetting.new, path: '/', method: :get) }

    it 'returns empty array when no path_level_param_names setting' do
      route = double('route', settings: {})
      expect(endpoint.send(:collect_path_param_names, route)).to eq([])
    end

    it 'returns empty array when setting is not an Array' do
      route = double('route', settings: { path_level_param_names: 'not_array' })
      expect(endpoint.send(:collect_path_param_names, route)).to eq([])
    end

    it 'converts symbol names to strings' do
      route = double('route', settings: { path_level_param_names: [:user_id, :post_id] })
      expect(endpoint.send(:collect_path_param_names, route)).to eq(%w[user_id post_id])
    end
  end

  describe 'servers_object helper' do
    let(:endpoint) { Grape::Endpoint.new(Grape::Util::InheritableSetting.new, path: '/', method: :get) }

    it 'returns nil when no servers option' do
      route = double('route', options: {})
      expect(endpoint.send(:servers_object, route)).to be_nil
    end

    it 'returns servers when option is present' do
      servers = [{ url: 'https://example.com' }]
      route = double('route', options: { servers: servers })
      expect(endpoint.send(:servers_object, route)).to eq(servers)
    end
  end

  describe 'extract_body_params helper' do
    let(:endpoint) { Grape::Endpoint.new(Grape::Util::InheritableSetting.new, path: '/', method: :get) }

    it 'returns empty array for nil parameters' do
      expect(endpoint.send(:extract_body_params, nil)).to eq([])
    end

    it 'returns empty array for non-array parameters' do
      expect(endpoint.send(:extract_body_params, 'not_array')).to eq([])
    end

    it 'selects body and formData parameters' do
      params = [
        { name: 'id', in: 'path' },
        { name: 'body', in: 'body' },
        { name: 'file', in: 'formData' },
        { name: 'q', in: 'query' }
      ]
      result = endpoint.send(:extract_body_params, params)
      expect(result.length).to eq(2)
      expect(result.map { |p| p[:name] }).to eq(%w[body file])
    end
  end
end
