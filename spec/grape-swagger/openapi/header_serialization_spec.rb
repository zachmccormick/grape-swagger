# frozen_string_literal: true

require 'spec_helper'

describe 'Header Object serialization fields (OpenAPI 3.1.0)' do
  # ============================================
  # Response header with explode
  # ============================================
  describe 'response header with explode' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items',
             success: {
               code: 200,
               message: 'Success',
               headers: {
                 'X-Items' => {
                   description: 'List of item IDs',
                   type: 'array',
                   items: { type: 'integer' },
                   explode: true
                 }
               }
             }
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

    it 'includes explode field in header' do
      headers = subject['paths']['/items']['get']['responses']['200']['headers']
      expect(headers['X-Items']['explode']).to eq(true)
    end

    it 'includes schema with array type' do
      headers = subject['paths']['/items']['get']['responses']['200']['headers']
      expect(headers['X-Items']['schema']['type']).to eq('array')
    end
  end

  # ============================================
  # Response header with default explode (false for simple style)
  # ============================================
  describe 'response header with default explode' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get data',
             success: {
               code: 200,
               message: 'Success',
               headers: {
                 'X-Tags' => {
                   description: 'Tags array',
                   type: 'array',
                   items: { type: 'string' }
                 }
               }
             }
        get '/data' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'defaults to explode=false for arrays with simple style' do
      headers = subject['paths']['/data']['get']['responses']['200']['headers']
      expect(headers['X-Tags']['explode']).to eq(false)
    end

    it 'defaults to simple style' do
      headers = subject['paths']['/data']['get']['responses']['200']['headers']
      expect(headers['X-Tags']['style']).to eq('simple')
    end
  end

  # ============================================
  # Response header with allowReserved
  # ============================================
  describe 'response header with allowReserved' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get resource',
             success: {
               code: 200,
               message: 'Success',
               headers: {
                 'X-Path' => {
                   description: 'Resource path',
                   type: 'string',
                   allowReserved: true
                 }
               }
             }
        get '/resource' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes allowReserved field' do
      headers = subject['paths']['/resource']['get']['responses']['200']['headers']
      expect(headers['X-Path']['allowReserved']).to eq(true)
    end
  end

  # ============================================
  # Response header with examples
  # ============================================
  describe 'response header with examples' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get status',
             success: {
               code: 200,
               message: 'Success',
               headers: {
                 'X-Rate-Limit' => {
                   description: 'Rate limit remaining',
                   type: 'integer',
                   examples: {
                     normal: {
                       summary: 'Normal usage',
                       value: 1000
                     },
                     limited: {
                       summary: 'Near limit',
                       value: 10
                     }
                   }
                 }
               }
             }
        get '/status' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes examples map' do
      headers = subject['paths']['/status']['get']['responses']['200']['headers']
      expect(headers['X-Rate-Limit']['examples']).to be_a(Hash)
      expect(headers['X-Rate-Limit']['examples']['normal']['value']).to eq(1000)
      expect(headers['X-Rate-Limit']['examples']['limited']['value']).to eq(10)
    end
  end

  # ============================================
  # Response header with content (alternative to schema)
  # ============================================
  describe 'response header with content' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get complex',
             success: {
               code: 200,
               message: 'Success',
               headers: {
                 'X-Metadata' => {
                   description: 'JSON metadata in header',
                   content: {
                     'application/json' => {
                       schema: {
                         type: 'object',
                         properties: {
                           version: { type: 'string' },
                           timestamp: { type: 'integer' }
                         }
                       }
                     }
                   }
                 }
               }
             }
        get '/complex' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes content field in header' do
      headers = subject['paths']['/complex']['get']['responses']['200']['headers']
      expect(headers['X-Metadata']['content']).to be_a(Hash)
      expect(headers['X-Metadata']['content']['application/json']['schema']['type']).to eq('object')
    end

    it 'does not include schema when content is present' do
      headers = subject['paths']['/complex']['get']['responses']['200']['headers']
      expect(headers['X-Metadata']).not_to have_key('schema')
    end
  end

  # ============================================
  # String header (no explode default)
  # ============================================
  describe 'simple string header' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get info',
             success: {
               code: 200,
               message: 'Success',
               headers: {
                 'X-Request-Id' => {
                   description: 'Request ID',
                   type: 'string'
                 }
               }
             }
        get '/info' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'does not include explode for string type' do
      headers = subject['paths']['/info']['get']['responses']['200']['headers']
      # explode is only added for arrays and objects
      expect(headers['X-Request-Id']).not_to have_key('explode')
    end

    it 'includes style for schema-based headers' do
      headers = subject['paths']['/info']['get']['responses']['200']['headers']
      expect(headers['X-Request-Id']['style']).to eq('simple')
    end
  end

  # ============================================
  # Swagger 2.0 (pass-through)
  # ============================================
  describe 'Swagger 2.0' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items',
             success: {
               code: 200,
               message: 'Success',
               headers: {
                 'X-Count' => {
                   description: 'Item count',
                   type: 'integer'
                 }
               }
             }
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

    it 'preserves original header format for Swagger 2.0' do
      headers = subject['paths']['/items']['get']['responses']['200']['headers']
      expect(headers['X-Count']['type']).to eq('integer')
      expect(headers['X-Count']['description']).to eq('Item count')
    end
  end
end
