# frozen_string_literal: true

require 'spec_helper'

describe 'Parameter content field (OpenAPI 3.1.0)' do
  # ============================================
  # Query parameter with content (JSON in query string)
  # ============================================
  describe 'query parameter with content' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Search with JSON filter'
        params do
          optional :filter, type: String, documentation: {
            desc: 'JSON filter object',
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    field: { type: 'string' },
                    operator: { type: 'string' },
                    value: { type: 'string' }
                  }
                }
              }
            }
          }
        end
        get '/search' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes content in parameter' do
      params = subject['paths']['/search']['get']['parameters']
      filter_param = params.find { |p| p['name'] == 'filter' }

      expect(filter_param['content']).to be_a(Hash)
      expect(filter_param['content']['application/json']).to be_a(Hash)
      expect(filter_param['content']['application/json']['schema']['type']).to eq('object')
    end
  end

  # ============================================
  # Multiple media types in content
  # ============================================
  describe 'multiple media types in content' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Accepts multiple formats'
        params do
          optional :data, type: String, documentation: {
            content: {
              'application/json' => {
                schema: { type: 'object' }
              },
              'application/xml' => {
                schema: { type: 'string' }
              }
            }
          }
        end
        get '/multi' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes all media types in content' do
      params = subject['paths']['/multi']['get']['parameters']
      data_param = params.find { |p| p['name'] == 'data' }

      expect(data_param['content'].keys).to include('application/json', 'application/xml')
    end
  end

  # ============================================
  # Content with example
  # ============================================
  describe 'content with example' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'With example in content'
        params do
          optional :query, type: String, documentation: {
            content: {
              'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    search: { type: 'string' }
                  }
                },
                example: { search: 'test query' }
              }
            }
          }
        end
        get '/example' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes example in media type object' do
      params = subject['paths']['/example']['get']['parameters']
      query_param = params.find { |p| p['name'] == 'query' }

      expect(query_param['content']['application/json']['example']).to eq({ 'search' => 'test query' })
    end
  end

  # ============================================
  # Swagger 2.0 (pass-through)
  # ============================================
  describe 'Swagger 2.0' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Search'
        params do
          optional :filter, type: String, documentation: {
            content: {
              'application/json' => {
                schema: { type: 'object' }
              }
            }
          }
        end
        get '/search' do
          []
        end

        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes content field (pass-through for Swagger 2.0)' do
      params = subject['paths']['/search']['get']['parameters']
      filter_param = params.find { |p| p['name'] == 'filter' }

      # In Swagger 2.0, content is passed through but not standard
      expect(filter_param['content']).to be_a(Hash)
    end
  end

  # ============================================
  # Regular parameter without content
  # ============================================
  describe 'regular parameter without content' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Normal search'
        params do
          optional :q, type: String, desc: 'Search query'
        end
        get '/search' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'uses schema for regular parameters' do
      params = subject['paths']['/search']['get']['parameters']
      q_param = params.find { |p| p['name'] == 'q' }

      expect(q_param['schema']).to be_a(Hash)
      expect(q_param).not_to have_key('content')
    end
  end
end
