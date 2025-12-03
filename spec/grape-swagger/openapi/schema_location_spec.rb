# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 Schema Location' do
  module SchemaLocationTest
    class Item < Grape::Entity
      expose :id, documentation: { type: Integer }
      expose :name, documentation: { type: String }
    end
  end

  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get items',
           success: { code: 200, message: 'Success', model: SchemaLocationTest::Item }
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

  describe 'BUG-003 & BUG-009: Schemas should be in components/schemas for OpenAPI 3.x' do
    it 'does not have definitions key' do
      expect(subject).not_to have_key('definitions')
    end

    it 'has components key' do
      expect(subject).to have_key('components')
    end

    it 'has components.schemas key' do
      expect(subject['components']).to have_key('schemas')
    end

    it 'places schemas under components/schemas' do
      schemas = subject['components']['schemas']
      expect(schemas.keys.any? { |k| k.include?('Item') }).to be true
    end

    it 'uses $ref paths pointing to components/schemas' do
      get_operation = subject['paths']['/items']['get']
      response_content = get_operation.dig('responses', '200', 'content', 'application/json', 'schema')
      expect(response_content['$ref']).to start_with('#/components/schemas/')
    end
  end
end
