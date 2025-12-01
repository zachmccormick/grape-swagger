# frozen_string_literal: true

require 'spec_helper'

describe 'Schema Validation Keywords' do
  before :all do
    module TheApi
      class SchemaValidationApi < Grape::API
        format :json

        desc 'Get scores with exclusive range'
        params do
          optional :score, type: Float, values: 0.0...1.0, desc: 'Score between 0 and 1 exclusive'
        end
        get '/scores' do
          { score: params[:score] }
        end

        add_swagger_documentation(
          openapi_version: '3.1.0',
          doc_version: '1.0.0',
          info: { title: 'Schema Validation API' }
        )
      end
    end
  end

  def app
    TheApi::SchemaValidationApi
  end

  describe 'exclusive range detection' do
    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates exclusiveMaximum for exclusive end range' do
      param = subject['paths']['/scores']['get']['parameters'].find { |p| p['name'] == 'score' }
      schema = param['schema']

      expect(schema['minimum']).to eq(0.0)
      expect(schema['exclusiveMaximum']).to eq(1.0)
      expect(schema).not_to have_key('maximum')
    end
  end

  describe 'inclusive range detection' do
    before :all do
      module TheApi
        class InclusiveRangeApi < Grape::API
          format :json

          desc 'Get ratings with inclusive range'
          params do
            optional :rating, type: Float, values: 0.0..5.0, desc: 'Rating from 0 to 5'
          end
          get '/ratings' do
            { rating: params[:rating] }
          end

          add_swagger_documentation(
            openapi_version: '3.1.0',
            doc_version: '1.0.0',
            info: { title: 'Inclusive Range API' }
          )
        end
      end
    end

    def app
      TheApi::InclusiveRangeApi
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates minimum and maximum for inclusive range' do
      param = subject['paths']['/ratings']['get']['parameters'].find { |p| p['name'] == 'rating' }
      schema = param['schema']

      expect(schema['minimum']).to eq(0.0)
      expect(schema['maximum']).to eq(5.0)
      expect(schema).not_to have_key('exclusiveMaximum')
    end
  end

  describe 'integer range detection' do
    before :all do
      module TheApi
        class IntegerRangeApi < Grape::API
          format :json

          desc 'Get pages with integer range'
          params do
            optional :page, type: Integer, values: 1..100, desc: 'Page number'
          end
          get '/items' do
            { page: params[:page] }
          end

          add_swagger_documentation(
            openapi_version: '3.1.0',
            doc_version: '1.0.0',
            info: { title: 'Integer Range API' }
          )
        end
      end
    end

    def app
      TheApi::IntegerRangeApi
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates minimum and maximum for integer range' do
      param = subject['paths']['/items']['get']['parameters'].find { |p| p['name'] == 'page' }
      schema = param['schema']

      expect(schema['minimum']).to eq(1)
      expect(schema['maximum']).to eq(100)
    end
  end

  describe 'unique_items documentation key' do
    before :all do
      module TheApi
        class UniqueItemsApi < Grape::API
          format :json

          desc 'Create items with unique tags'
          params do
            optional :tags, type: Array[String], documentation: { unique_items: true }
          end
          post '/items' do
            { tags: params[:tags] }
          end

          add_swagger_documentation(
            openapi_version: '3.1.0',
            doc_version: '1.0.0',
            info: { title: 'Unique Items API' }
          )
        end
      end
    end

    def app
      TheApi::UniqueItemsApi
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates uniqueItems in schema' do
      # In OpenAPI 3.1.0, POST body params are in components/schemas
      schema = subject['components']['schemas']['postItems']
      prop = schema['properties']['tags']

      expect(prop['uniqueItems']).to eq(true)
    end
  end

  describe 'numeric validation documentation keys' do
    before :all do
      module TheApi
        class NumericValidationApi < Grape::API
          format :json

          desc 'Get ratings with numeric validation'
          params do
            optional :rating, type: Float, documentation: {
              exclusive_minimum: 0,
              exclusive_maximum: 5,
              multiple_of: 0.5
            }
          end
          get '/ratings' do
            { rating: params[:rating] }
          end

          add_swagger_documentation(
            openapi_version: '3.1.0',
            doc_version: '1.0.0',
            info: { title: 'Numeric Validation API' }
          )
        end
      end
    end

    def app
      TheApi::NumericValidationApi
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates exclusiveMinimum, exclusiveMaximum, and multipleOf' do
      param = subject['paths']['/ratings']['get']['parameters'].find { |p| p['name'] == 'rating' }
      schema = param['schema']

      expect(schema['exclusiveMinimum']).to eq(0)
      expect(schema['exclusiveMaximum']).to eq(5)
      expect(schema['multipleOf']).to eq(0.5)
    end
  end

  describe 'numeric validation in POST request body' do
    before :all do
      module TheApi
        class NumericValidationPostApi < Grape::API
          format :json

          desc 'Create item with numeric validation in body'
          params do
            requires :price, type: Float, documentation: {
              exclusive_minimum: 0,
              exclusive_maximum: 1000,
              multiple_of: 0.01
            }
          end
          post '/items' do
            { price: params[:price] }
          end

          add_swagger_documentation(
            openapi_version: '3.1.0',
            doc_version: '1.0.0',
            info: { title: 'Numeric Validation POST API' }
          )
        end
      end
    end

    def app
      TheApi::NumericValidationPostApi
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'generates exclusiveMinimum, exclusiveMaximum, and multipleOf in request body schema' do
      # In OpenAPI 3.1.0, POST body params are in components/schemas
      schema = subject['components']['schemas']['postItems']
      prop = schema['properties']['price']

      expect(prop['exclusiveMinimum']).to eq(0)
      expect(prop['exclusiveMaximum']).to eq(1000)
      expect(prop['multipleOf']).to eq(0.01)
    end
  end
end
