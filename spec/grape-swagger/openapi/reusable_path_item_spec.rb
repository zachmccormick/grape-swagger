# frozen_string_literal: true

require 'spec_helper'

describe 'Reusable Path Items (OpenAPI 3.1.0)' do
  before do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  # ============================================
  # ReusablePathItem DSL
  # ============================================
  describe 'ReusablePathItem DSL' do
    let(:path_item_class) do
      Class.new(GrapeSwagger::ReusablePathItem) do
        summary 'User Item Operations'
        description 'Standard CRUD operations for a single user resource'

        parameter :id, in: :path, type: Integer, required: true, desc: 'User ID'

        get_operation do
          summary 'Get user by ID'
          description 'Retrieves a user by their unique identifier'
          operation_id 'getUserById'
          tags 'users'
          response 200, description: 'User found'
          response 404, description: 'User not found'
        end

        put_operation do
          summary 'Update user'
          operation_id 'updateUser'
          tags 'users'
          request_body 'application/json', schema: { type: 'object' }
          response 200, description: 'User updated'
        end

        delete_operation do
          summary 'Delete user'
          operation_id 'deleteUser'
          deprecated true
          response 204, description: 'User deleted'
        end
      end
    end

    before do
      stub_const('UserItemPath', path_item_class)
    end

    it 'generates path item with summary' do
      openapi = UserItemPath.to_openapi
      expect(openapi[:summary]).to eq('User Item Operations')
    end

    it 'generates path item with description' do
      openapi = UserItemPath.to_openapi
      expect(openapi[:description]).to eq('Standard CRUD operations for a single user resource')
    end

    it 'generates path-level parameters' do
      openapi = UserItemPath.to_openapi
      expect(openapi[:parameters]).to be_an(Array)
      expect(openapi[:parameters].first[:name]).to eq('id')
      expect(openapi[:parameters].first[:in]).to eq('path')
      expect(openapi[:parameters].first[:required]).to eq(true)
    end

    it 'generates GET operation' do
      openapi = UserItemPath.to_openapi
      expect(openapi[:get]).to be_a(Hash)
      expect(openapi[:get][:summary]).to eq('Get user by ID')
      expect(openapi[:get][:operationId]).to eq('getUserById')
    end

    it 'generates PUT operation with request body' do
      openapi = UserItemPath.to_openapi
      expect(openapi[:put]).to be_a(Hash)
      expect(openapi[:put][:requestBody]).to be_a(Hash)
      expect(openapi[:put][:requestBody][:content]).to have_key('application/json')
    end

    it 'generates DELETE operation with deprecated flag' do
      openapi = UserItemPath.to_openapi
      expect(openapi[:delete]).to be_a(Hash)
      expect(openapi[:delete][:deprecated]).to eq(true)
    end

    it 'generates proper responses' do
      openapi = UserItemPath.to_openapi
      expect(openapi[:get][:responses]).to have_key(200)
      expect(openapi[:get][:responses]).to have_key(404)
      expect(openapi[:get][:responses][200][:description]).to eq('User found')
    end
  end

  # ============================================
  # ComponentsRegistry Integration
  # ============================================
  describe 'ComponentsRegistry integration' do
    let(:path_item_class) do
      Class.new(GrapeSwagger::ReusablePathItem) do
        summary 'Item operations'

        get_operation do
          summary 'Get item'
          response 200, description: 'OK'
        end
      end
    end

    before do
      stub_const('ItemPath', path_item_class)
      GrapeSwagger::ComponentsRegistry.register_path_item(ItemPath)
    end

    it 'registers path item in registry' do
      expect(GrapeSwagger::ComponentsRegistry.path_items).to have_key('ItemPath')
    end

    it 'can find registered path item' do
      found = GrapeSwagger::ComponentsRegistry.find_path_item!('ItemPath')
      expect(found).to eq(ItemPath)
    end

    it 'raises error for unknown path item' do
      expect do
        GrapeSwagger::ComponentsRegistry.find_path_item!('UnknownPath')
      end.to raise_error(GrapeSwagger::ComponentNotFoundError)
    end

    it 'includes pathItems in to_openapi output' do
      openapi = GrapeSwagger::ComponentsRegistry.to_openapi
      expect(openapi).to have_key(:pathItems)
      expect(openapi[:pathItems]).to have_key('ItemPath')
    end
  end

  # ============================================
  # Path Item $ref in Grape API
  # ============================================
  describe 'Path Item $ref in Grape API' do
    let(:user_path_item) do
      Class.new(GrapeSwagger::ReusablePathItem) do
        summary 'User by ID'
        description 'Operations on a single user'

        parameter :id, in: :path, type: Integer, required: true, desc: 'User ID'

        get_operation do
          summary 'Get user'
          response 200, description: 'User found'
          response 404, description: 'Not found'
        end

        put_operation do
          summary 'Update user'
          response 200, description: 'Updated'
        end

        delete_operation do
          summary 'Delete user'
          response 204, description: 'Deleted'
        end
      end
    end

    before do
      stub_const('UserByIdPath', user_path_item)
      GrapeSwagger::ComponentsRegistry.register_path_item(UserByIdPath)
    end

    def app
      Class.new(Grape::API) do
        format :json

        resource :users do
          route_setting :path_ref, 'UserByIdPath'
          route_param :id do
            get do
              { id: params[:id] }
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

    it 'generates $ref for the path item' do
      path = subject['paths']['/users/{id}']
      expect(path).to have_key('$ref')
      expect(path['$ref']).to eq('#/components/pathItems/UserByIdPath')
    end

    it 'includes pathItems in components' do
      components = subject['components']
      expect(components).to have_key('pathItems')
      expect(components['pathItems']).to have_key('UserByIdPath')
    end

    it 'path item has the defined operations' do
      path_item = subject['components']['pathItems']['UserByIdPath']
      expect(path_item).to have_key('get')
      expect(path_item).to have_key('put')
      expect(path_item).to have_key('delete')
    end

    it 'path item has the summary and description' do
      path_item = subject['components']['pathItems']['UserByIdPath']
      expect(path_item['summary']).to eq('User by ID')
      expect(path_item['description']).to eq('Operations on a single user')
    end
  end

  # ============================================
  # Custom Component Names
  # ============================================
  describe 'custom component names' do
    let(:path_item_class) do
      Class.new(GrapeSwagger::ReusablePathItem) do
        component_name 'CustomUserPath'
        summary 'Custom named path item'

        get_operation do
          summary 'Get'
          response 200, description: 'OK'
        end
      end
    end

    before do
      stub_const('SomeInternalClass', path_item_class)
      GrapeSwagger::ComponentsRegistry.register_path_item(SomeInternalClass)
    end

    it 'uses custom component name' do
      expect(GrapeSwagger::ComponentsRegistry.path_items).to have_key('CustomUserPath')
    end

    it 'can find by custom name' do
      found = GrapeSwagger::ComponentsRegistry.find_path_item!('CustomUserPath')
      expect(found).to eq(SomeInternalClass)
    end
  end

  # ============================================
  # All HTTP Methods
  # ============================================
  describe 'all HTTP methods' do
    let(:path_item_class) do
      Class.new(GrapeSwagger::ReusablePathItem) do
        get_operation do
          summary 'GET'
          response 200, description: 'OK'
        end

        post_operation do
          summary 'POST'
          response 201, description: 'Created'
        end

        put_operation do
          summary 'PUT'
          response 200, description: 'OK'
        end

        patch_operation do
          summary 'PATCH'
          response 200, description: 'OK'
        end

        delete_operation do
          summary 'DELETE'
          response 204, description: 'No Content'
        end

        options_operation do
          summary 'OPTIONS'
          response 200, description: 'OK'
        end

        head_operation do
          summary 'HEAD'
          response 200, description: 'OK'
        end

        trace_operation do
          summary 'TRACE'
          response 200, description: 'OK'
        end
      end
    end

    before do
      stub_const('AllMethodsPath', path_item_class)
    end

    it 'generates all HTTP method operations' do
      openapi = AllMethodsPath.to_openapi
      expect(openapi).to have_key(:get)
      expect(openapi).to have_key(:post)
      expect(openapi).to have_key(:put)
      expect(openapi).to have_key(:patch)
      expect(openapi).to have_key(:delete)
      expect(openapi).to have_key(:options)
      expect(openapi).to have_key(:head)
      expect(openapi).to have_key(:trace)
    end
  end
end
