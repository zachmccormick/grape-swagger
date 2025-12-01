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
end
