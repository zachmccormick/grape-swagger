# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 Request Body Schema' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Create item'
      params do
        requires :name, type: String, desc: 'Item name'
        requires :price, type: Float, desc: 'Item price'
        optional :description, type: String, desc: 'Item description'
      end
      post '/items' do
        { id: 1, name: params[:name], price: params[:price] }
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:post_operation) { subject['paths']['/items']['post'] }
  let(:request_body_schema) do
    post_operation.dig('requestBody', 'content', 'application/json', 'schema')
  end

  describe 'BUG-011: Request body schema should not be empty' do
    it 'has requestBody' do
      expect(post_operation).to have_key('requestBody')
    end

    it 'has content in requestBody' do
      expect(post_operation['requestBody']).to have_key('content')
    end

    it 'has schema in content' do
      expect(post_operation.dig('requestBody', 'content', 'application/json')).to have_key('schema')
    end

    it 'references a schema with $ref' do
      expect(request_body_schema).to have_key('$ref')
      expect(request_body_schema['$ref']).to start_with('#/components/schemas/')
    end

    describe 'referenced schema' do
      let(:schema_name) { request_body_schema['$ref'].split('/').last }
      let(:referenced_schema) { subject['components']['schemas'][schema_name] }

      it 'exists in components/schemas' do
        expect(referenced_schema).not_to be_nil
      end

      it 'has non-empty properties' do
        properties = referenced_schema['properties']
        expect(properties).not_to be_nil
        expect(properties).not_to be_empty
      end

      it 'includes all required params in properties' do
        properties = referenced_schema['properties']
        expect(properties).to have_key('name')
        expect(properties).to have_key('price')
      end

      it 'includes optional params in properties' do
        properties = referenced_schema['properties']
        expect(properties).to have_key('description')
      end
    end
  end
end
