# frozen_string_literal: true

require 'spec_helper'

# Entity for response serialization in the integration test
module FullSpecIntegration
  module Entities
    class Widget < Grape::Entity
      expose :id, documentation: { type: Integer, desc: 'Widget ID' }
      expose :name, documentation: { type: String, desc: 'Widget name' }
      expose :price, documentation: { type: Float, desc: 'Widget price' }
    end
  end
end

# Full-featured API exercising key OpenAPI 3.1.0 capabilities
class FullSpecIntegrationAPI < Grape::API
  format :json

  resource :widgets do
    desc 'List widgets',
         is_array: true,
         success: FullSpecIntegration::Entities::Widget
    params do
      optional :category, type: String, desc: 'Filter by category'
      optional :page, type: Integer, desc: 'Page number'
    end
    get do
      present [], with: FullSpecIntegration::Entities::Widget
    end

    desc 'Get a widget',
         success: FullSpecIntegration::Entities::Widget
    params do
      requires :id, type: Integer, desc: 'Widget ID'
    end
    get ':id' do
      present({ id: params[:id], name: 'Sprocket', price: 9.99 },
              with: FullSpecIntegration::Entities::Widget)
    end

    desc 'Create a widget',
         success: { code: 201, model: FullSpecIntegration::Entities::Widget, message: 'Widget created' }
    params do
      requires :name, type: String, desc: 'Widget name'
      requires :price, type: Float, desc: 'Widget price'
      optional :category, type: String, desc: 'Widget category'
    end
    post do
      status 201
      present({ id: 1, name: params[:name], price: params[:price] },
              with: FullSpecIntegration::Entities::Widget)
    end

    desc 'Update a widget',
         success: FullSpecIntegration::Entities::Widget
    params do
      requires :id, type: Integer, desc: 'Widget ID'
      optional :name, type: String, desc: 'Widget name'
      optional :price, type: Float, desc: 'Widget price'
    end
    put ':id' do
      present({ id: params[:id], name: params[:name], price: params[:price] },
              with: FullSpecIntegration::Entities::Widget)
    end
  end

  add_swagger_documentation(
    openapi_version: '3.1.0',
    doc_version: '2.0.0',
    info: {
      title: 'Integration Test API',
      description: 'Full integration test for OpenAPI 3.1.0'
    },
    security_definitions: {
      api_key: {
        type: 'apiKey',
        name: 'X-API-Key',
        in: 'header',
        description: 'API key authentication'
      },
      oauth2: {
        type: 'oauth2',
        description: 'OAuth2 authentication',
        flows: {
          authorizationCode: {
            authorization_url: 'https://auth.example.com/authorize',
            token_url: 'https://auth.example.com/token',
            scopes: {
              'read' => 'Read access',
              'write' => 'Write access'
            }
          }
        }
      }
    },
    security: [{ api_key: [] }]
  )
end

# Swagger 2.0 API for backward compatibility comparison
class FullSpecSwagger2API < Grape::API
  format :json

  resource :widgets do
    desc 'List widgets'
    params do
      optional :category, type: String, desc: 'Filter by category'
    end
    get do
      []
    end

    desc 'Create a widget'
    params do
      requires :name, type: String, desc: 'Widget name'
    end
    post do
      { id: 1, name: params[:name] }
    end
  end

  add_swagger_documentation(
    info: {
      title: 'Swagger 2 Comparison API',
      version: '1.0.0'
    }
  )
end

describe 'Full OpenAPI 3.1.0 Spec Integration' do
  context 'OpenAPI 3.1.0 API' do
    def app
      FullSpecIntegrationAPI
    end

    let(:spec) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    describe 'top-level structure' do
      it 'has openapi version 3.1.0' do
        expect(spec['openapi']).to eq('3.1.0')
      end

      it 'has info object with title and version' do
        expect(spec['info']['title']).to eq('Integration Test API')
        expect(spec['info']['version']).to eq('2.0.0')
        expect(spec['info']['description']).to eq('Full integration test for OpenAPI 3.1.0')
      end

      it 'has paths object' do
        expect(spec['paths']).to be_a(Hash)
        expect(spec['paths']).not_to be_empty
      end

      it 'does not have swagger key' do
        expect(spec).not_to have_key('swagger')
      end

      it 'does not have top-level definitions key' do
        expect(spec).not_to have_key('definitions')
      end

      it 'does not have top-level produces key' do
        expect(spec).not_to have_key('produces')
      end

      it 'does not have top-level consumes key' do
        expect(spec).not_to have_key('consumes')
      end
    end

    describe 'POST endpoint requestBody (PR 7)' do
      let(:post_op) { spec['paths']['/widgets']['post'] }

      it 'has requestBody' do
        expect(post_op).to have_key('requestBody')
      end

      it 'has content in requestBody' do
        expect(post_op['requestBody']).to have_key('content')
      end

      it 'has application/json content type' do
        expect(post_op['requestBody']['content']).to have_key('application/json')
      end

      it 'has schema in content' do
        json = post_op['requestBody']['content']['application/json']
        expect(json).to have_key('schema')
      end

      it 'does not have in:body parameters' do
        params = post_op['parameters']
        if params
          body_params = params.select { |p| p['in'] == 'body' }
          expect(body_params).to be_empty
        end
      end
    end

    describe 'PUT endpoint with mixed params' do
      let(:put_op) { spec['paths']['/widgets/{id}']['put'] }

      it 'has requestBody for body params' do
        expect(put_op).to have_key('requestBody')
      end

      it 'keeps path parameter in parameters array' do
        params = put_op['parameters']
        if params
          path_params = params.select { |p| p['in'] == 'path' }
          expect(path_params).not_to be_empty
        end
      end
    end

    describe 'query parameter schema wrapping (PR 9)' do
      let(:get_op) { spec['paths']['/widgets']['get'] }
      let(:params) { get_op['parameters'] }

      it 'wraps query param type in schema object' do
        category_param = params.find { |p| p['name'] == 'category' }
        expect(category_param).not_to be_nil
        expect(category_param).to have_key('schema')
        expect(category_param['schema']['type']).to eq('string')
      end

      it 'does not have type at parameter level' do
        category_param = params.find { |p| p['name'] == 'category' }
        expect(category_param).not_to have_key('type')
      end

      it 'adds style for query parameters' do
        category_param = params.find { |p| p['name'] == 'category' }
        expect(category_param['style']).to eq('form')
      end
    end

    describe 'path parameter schema wrapping (PR 9)' do
      let(:get_op) { spec['paths']['/widgets/{id}']['get'] }
      let(:params) { get_op['parameters'] }

      it 'wraps path param type in schema object' do
        id_param = params.find { |p| p['name'] == 'id' }
        expect(id_param).not_to be_nil
        expect(id_param['schema']['type']).to eq('integer')
      end

      it 'adds simple style for path parameters' do
        id_param = params.find { |p| p['name'] == 'id' }
        expect(id_param['style']).to eq('simple')
      end
    end

    describe 'components/schemas and $ref format (PR 3, PR 5)' do
      it 'places definitions under components/schemas' do
        expect(spec).to have_key('components')
        expect(spec['components']).to have_key('schemas')
        expect(spec['components']['schemas']).not_to be_empty
      end

      it 'uses #/components/schemas/ in $ref paths' do
        # Collect all $ref values from the spec
        refs = collect_refs(spec)
        schema_refs = refs.select { |r| r.include?('schemas') }
        expect(schema_refs).not_to be_empty
        schema_refs.each do |ref|
          expect(ref).to start_with('#/components/schemas/')
        end
      end

      it 'does not use #/definitions/ in any $ref path' do
        refs = collect_refs(spec)
        definitions_refs = refs.select { |r| r.include?('#/definitions/') }
        expect(definitions_refs).to be_empty
      end
    end

    describe 'security schemes (PR 11)' do
      it 'places security schemes under components/securitySchemes' do
        expect(spec['components']).to have_key('securitySchemes')
        schemes = spec['components']['securitySchemes']
        expect(schemes).to have_key('api_key')
        expect(schemes).to have_key('oauth2')
      end

      it 'formats API key scheme correctly' do
        api_key = spec['components']['securitySchemes']['api_key']
        expect(api_key['type']).to eq('apiKey')
        expect(api_key['name']).to eq('X-API-Key')
        expect(api_key['in']).to eq('header')
      end

      it 'formats OAuth2 scheme with flows' do
        oauth2 = spec['components']['securitySchemes']['oauth2']
        expect(oauth2['type']).to eq('oauth2')
        expect(oauth2['flows']).to have_key('authorizationCode')
        flow = oauth2['flows']['authorizationCode']
        expect(flow['authorizationUrl']).to be_a(String)
        expect(flow['tokenUrl']).to be_a(String)
        expect(flow['scopes']).to be_a(Hash)
      end

      it 'includes global security requirement' do
        expect(spec['security']).to be_an(Array)
        expect(spec['security']).to include({ 'api_key' => [] })
      end

      it 'does not have top-level securityDefinitions' do
        expect(spec).not_to have_key('securityDefinitions')
      end
    end

    describe 'response content wrapping (PR 8)' do
      let(:get_op) { spec['paths']['/widgets']['get'] }

      it 'has responses object' do
        expect(get_op).to have_key('responses')
      end

      it 'has 200 response with description' do
        response_200 = get_op['responses']['200']
        expect(response_200).to have_key('description')
      end
    end
  end

  context 'Swagger 2.0 backward compatibility' do
    def app
      FullSpecSwagger2API
    end

    let(:spec) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'uses swagger 2.0 format' do
      expect(spec['swagger']).to eq('2.0')
    end

    it 'has top-level produces' do
      expect(spec).to have_key('produces')
    end

    it 'keeps body params in parameters (no requestBody)' do
      post_op = spec['paths']['/widgets']['post']
      expect(post_op).not_to have_key('requestBody')
      expect(post_op['parameters']).not_to be_nil
    end

    it 'does not wrap query param type in schema' do
      get_op = spec['paths']['/widgets']['get']
      params = get_op['parameters']
      category_param = params.find { |p| p['name'] == 'category' }
      expect(category_param).to have_key('type')
      expect(category_param).not_to have_key('schema')
    end
  end

  # Helper to recursively collect all $ref values from a nested Hash/Array
  def collect_refs(obj, refs = [])
    case obj
    when Hash
      obj.each do |key, value|
        if key == '$ref' && value.is_a?(String)
          refs << value
        else
          collect_refs(value, refs)
        end
      end
    when Array
      obj.each { |item| collect_refs(item, refs) }
    end
    refs
  end
end
