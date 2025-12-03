# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 Operation Properties' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get items',
           success: { code: 200, message: 'Success' },
           failure: [{ code: 404, message: 'Not found' }]
      get '/items' do
        []
      end

      desc 'Create item',
           success: { code: 201, message: 'Created' }
      params do
        requires :name, type: String
      end
      post '/items' do
        { name: params[:name] }
      end

      desc 'Update item'
      params do
        requires :id, type: Integer
        requires :name, type: String
      end
      put '/items/:id' do
        { id: params[:id], name: params[:name] }
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'BUG-001: produces should not be in operations for OpenAPI 3.1.0' do
    it 'does not include produces in GET operations' do
      get_operation = subject['paths']['/items']['get']
      expect(get_operation).not_to have_key('produces')
    end

    it 'does not include produces in POST operations' do
      post_operation = subject['paths']['/items']['post']
      expect(post_operation).not_to have_key('produces')
    end

    it 'does not include produces in PUT operations' do
      put_operation = subject['paths']['/items/{id}']['put']
      expect(put_operation).not_to have_key('produces')
    end
  end

  describe 'BUG-002: consumes should not be in operations for OpenAPI 3.1.0' do
    it 'does not include consumes in GET operations' do
      get_operation = subject['paths']['/items']['get']
      expect(get_operation).not_to have_key('consumes')
    end

    it 'does not include consumes in POST operations' do
      post_operation = subject['paths']['/items']['post']
      expect(post_operation).not_to have_key('consumes')
    end

    it 'does not include consumes in PUT operations' do
      put_operation = subject['paths']['/items/{id}']['put']
      expect(put_operation).not_to have_key('consumes')
    end
  end

  describe 'OpenAPI 3.1.0 uses requestBody instead of consumes' do
    it 'uses requestBody with content for POST' do
      post_operation = subject['paths']['/items']['post']
      expect(post_operation).to have_key('requestBody')
      expect(post_operation['requestBody']).to have_key('content')
    end

    it 'uses requestBody with content for PUT' do
      put_operation = subject['paths']['/items/{id}']['put']
      expect(put_operation).to have_key('requestBody')
      expect(put_operation['requestBody']).to have_key('content')
    end
  end
end
