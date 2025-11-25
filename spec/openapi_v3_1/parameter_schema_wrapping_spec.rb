# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 Parameter Schema Wrapping Integration' do
  before :all do
    module TheApi
      class ParameterApi < Grape::API
        format :json

        desc 'Get items with various parameter types'
        params do
          requires :id, type: Integer, desc: 'Item ID'
          optional :name, type: String, desc: 'Item name', default: 'Default Name'
          optional :status, type: String, desc: 'Status filter', values: %w[active inactive], default: 'active'
          optional :created_at, type: DateTime, desc: 'Creation date'
          optional :tags, type: Array[String], desc: 'Tags'
          optional :page, type: Integer, desc: 'Page number', values: 1..100
        end
        get '/items' do
          { items: [] }
        end

        desc 'Get item by ID'
        params do
          requires :id, type: Integer, desc: 'Item ID'
        end
        get '/items/:id' do
          { id: params[:id] }
        end

        desc 'Search with header'
        params do
          requires :query, type: String, desc: 'Search query'
        end
        get '/search', headers: {
          'X-API-Key' => {
            description: 'API Key',
            required: true
          }
        } do
          { results: [] }
        end

        add_swagger_documentation(
          openapi_version: '3.1.0',
          doc_version: '1.0.0',
          info: { title: 'Parameter API' }
        )
      end
    end
  end

  def app
    TheApi::ParameterApi
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'OpenAPI 3.1.0 parameter wrapping' do
    context 'GET /items endpoint' do
      let(:parameters) { subject.dig('paths', '/items', 'get', 'parameters') }

      it 'wraps query parameters in schema objects' do
        expect(parameters).to be_an(Array)

        # Check that all query parameters have schema objects
        query_params = parameters.select { |p| p['in'] == 'query' }
        expect(query_params).not_to be_empty

        query_params.each do |param|
          expect(param).to have_key('schema')
          expect(param['schema']).to be_a(Hash)
        end
      end

      it 'moves type into schema for query parameters' do
        name_param = parameters.find { |p| p['name'] == 'name' }
        expect(name_param).not_to be_nil
        expect(name_param).not_to have_key('type')
        expect(name_param['schema']).to have_key('type')
        expect(name_param['schema']['type']).to eq('string')
      end

      it 'moves default into schema' do
        name_param = parameters.find { |p| p['name'] == 'name' }
        expect(name_param).not_to be_nil
        expect(name_param).not_to have_key('default')
        expect(name_param['schema']).to have_key('default')
        expect(name_param['schema']['default']).to eq('Default Name')
      end

      it 'moves enum into schema' do
        status_param = parameters.find { |p| p['name'] == 'status' }
        expect(status_param).not_to be_nil
        expect(status_param).not_to have_key('enum')
        expect(status_param['schema']).to have_key('enum')
        expect(status_param['schema']['enum']).to eq(%w[active inactive])
      end

      it 'moves minimum and maximum into schema for range values' do
        page_param = parameters.find { |p| p['name'] == 'page' }
        expect(page_param).not_to be_nil
        expect(page_param).not_to have_key('minimum')
        expect(page_param).not_to have_key('maximum')
        expect(page_param['schema']).to have_key('minimum')
        expect(page_param['schema']).to have_key('maximum')
        expect(page_param['schema']['minimum']).to eq(1)
        expect(page_param['schema']['maximum']).to eq(100)
      end

      it 'preserves parameter-level fields' do
        name_param = parameters.find { |p| p['name'] == 'name' }
        expect(name_param).not_to be_nil
        expect(name_param).to have_key('name')
        expect(name_param).to have_key('in')
        expect(name_param).to have_key('description')
        expect(name_param).to have_key('required')
      end

      it 'adds default style for query parameters' do
        name_param = parameters.find { |p| p['name'] == 'name' }
        expect(name_param).not_to be_nil
        expect(name_param).to have_key('style')
        expect(name_param['style']).to eq('form')
      end

      it 'adds explode for array query parameters' do
        tags_param = parameters.find { |p| p['name'] == 'tags' }
        expect(tags_param).not_to be_nil
        expect(tags_param).to have_key('explode')
        expect(tags_param['explode']).to be true
      end
    end

    context 'GET /items/:id endpoint' do
      let(:parameters) { subject.dig('paths', '/items/{id}', 'get', 'parameters') }

      it 'wraps path parameters in schema objects' do
        expect(parameters).to be_an(Array)

        path_params = parameters.select { |p| p['in'] == 'path' }
        expect(path_params).not_to be_empty

        path_params.each do |param|
          expect(param).to have_key('schema')
          expect(param['schema']).to be_a(Hash)
        end
      end

      it 'adds simple style for path parameters' do
        id_param = parameters.find { |p| p['name'] == 'id' }
        expect(id_param).not_to be_nil
        expect(id_param).to have_key('style')
        expect(id_param['style']).to eq('simple')
      end

      it 'marks path parameters as required' do
        id_param = parameters.find { |p| p['name'] == 'id' }
        expect(id_param).not_to be_nil
        expect(id_param['required']).to be true
      end
    end

    context 'GET /search endpoint' do
      let(:parameters) { subject.dig('paths', '/search', 'get', 'parameters') }

      it 'wraps header parameters in schema objects' do
        header_params = parameters.select { |p| p['in'] == 'header' }
        expect(header_params).not_to be_empty

        header_params.each do |param|
          expect(param).to have_key('schema')
          expect(param['schema']).to be_a(Hash)
        end
      end

      it 'adds simple style for header parameters' do
        api_key_param = parameters.find { |p| p['name'] == 'X-API-Key' }
        expect(api_key_param).not_to be_nil
        expect(api_key_param).to have_key('style')
        expect(api_key_param['style']).to eq('simple')
      end
    end
  end

  describe 'Swagger 2.0 compatibility' do
    before :all do
      module TheApi
        class Swagger2Api < Grape::API
          format :json

          desc 'Get items'
          params do
            requires :id, type: Integer, desc: 'Item ID'
            optional :name, type: String, desc: 'Item name', default: 'Default'
          end
          get '/items' do
            { items: [] }
          end

          add_swagger_documentation(
            swagger_version: '2.0',
            doc_version: '1.0.0',
            info: { title: 'Swagger 2.0 API' }
          )
        end
      end
    end

    def app
      TheApi::Swagger2Api
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'does not wrap parameters for Swagger 2.0' do
      parameters = subject.dig('paths', '/items', 'get', 'parameters')
      expect(parameters).to be_an(Array)

      parameters.each do |param|
        # Swagger 2.0 should NOT have schema objects
        expect(param).not_to have_key('schema')
        # Instead, type should be at parameter level
        expect(param).to have_key('type') if param['name'] != 'id' || param['in'] != 'path'
      end
    end

    it 'keeps type at parameter level for Swagger 2.0' do
      parameters = subject.dig('paths', '/items', 'get', 'parameters')
      name_param = parameters.find { |p| p['name'] == 'name' }
      expect(name_param).not_to be_nil
      expect(name_param['type']).to eq('string')
      expect(name_param).not_to have_key('schema')
    end

    it 'keeps default at parameter level for Swagger 2.0' do
      parameters = subject.dig('paths', '/items', 'get', 'parameters')
      name_param = parameters.find { |p| p['name'] == 'name' }
      expect(name_param).not_to be_nil
      expect(name_param['default']).to eq('Default')
      expect(name_param).not_to have_key('schema')
    end
  end
end
