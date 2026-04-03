# frozen_string_literal: true

require 'spec_helper'

describe 'Reference Object summary/description overrides (OpenAPI 3.1.0)' do
  # ============================================
  # Parameter reference with description override
  # ============================================
  describe 'parameter reference with description override' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'List items'
        params do
          optional :page, type: Integer, documentation: {
            ref: '#/components/parameters/PageParam',
            ref_description: 'Page number for this specific endpoint'
          }
        end
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

    it 'includes $ref with description override' do
      params = subject['paths']['/items']['get']['parameters']
      page_param = params.find { |p| p['$ref'] }

      expect(page_param['$ref']).to eq('#/components/parameters/PageParam')
      expect(page_param['description']).to eq('Page number for this specific endpoint')
    end
  end

  # ============================================
  # Parameter reference with summary override
  # ============================================
  describe 'parameter reference with summary override' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Search'
        params do
          optional :limit, type: Integer, documentation: {
            ref: '#/components/parameters/LimitParam',
            ref_summary: 'Search result limit'
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

    it 'includes $ref with summary override' do
      params = subject['paths']['/search']['get']['parameters']
      limit_param = params.find { |p| p['$ref'] }

      expect(limit_param['$ref']).to eq('#/components/parameters/LimitParam')
      expect(limit_param['summary']).to eq('Search result limit')
    end
  end

  # ============================================
  # Parameter reference with both summary and description
  # ============================================
  describe 'parameter reference with both overrides' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get data'
        params do
          optional :sort, type: String, documentation: {
            ref: '#/components/parameters/SortParam',
            ref_summary: 'Custom sort field',
            ref_description: 'Sort field specific to this endpoint. Valid values: name, date, priority'
          }
        end
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

    it 'includes both summary and description overrides' do
      params = subject['paths']['/data']['get']['parameters']
      sort_param = params.find { |p| p['$ref'] }

      expect(sort_param['$ref']).to eq('#/components/parameters/SortParam')
      expect(sort_param['summary']).to eq('Custom sort field')
      expect(sort_param['description']).to eq('Sort field specific to this endpoint. Valid values: name, date, priority')
    end
  end

  # ============================================
  # Parameter reference without overrides
  # ============================================
  describe 'parameter reference without overrides' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'List'
        params do
          optional :offset, type: Integer, documentation: {
            ref: '#/components/parameters/OffsetParam'
          }
        end
        get '/list' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes only $ref without overrides' do
      params = subject['paths']['/list']['get']['parameters']
      offset_param = params.find { |p| p['$ref'] }

      expect(offset_param['$ref']).to eq('#/components/parameters/OffsetParam')
      expect(offset_param).not_to have_key('summary')
      expect(offset_param).not_to have_key('description')
    end
  end

  # ============================================
  # Multiple parameters with different overrides
  # ============================================
  describe 'multiple parameters with different overrides' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Advanced search'
        params do
          optional :page, type: Integer, documentation: {
            ref: '#/components/parameters/PageParam',
            ref_description: 'Results page number'
          }
          optional :limit, type: Integer, documentation: {
            ref: '#/components/parameters/LimitParam',
            ref_summary: 'Max results'
          }
          optional :sort, type: String, documentation: {
            ref: '#/components/parameters/SortParam'
          }
        end
        get '/advanced' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'handles multiple references with different overrides' do
      params = subject['paths']['/advanced']['get']['parameters']

      page_param = params.find { |p| p['$ref']&.include?('PageParam') }
      limit_param = params.find { |p| p['$ref']&.include?('LimitParam') }
      sort_param = params.find { |p| p['$ref']&.include?('SortParam') }

      expect(page_param['description']).to eq('Results page number')
      expect(page_param).not_to have_key('summary')

      expect(limit_param['summary']).to eq('Max results')
      expect(limit_param).not_to have_key('description')

      expect(sort_param).not_to have_key('summary')
      expect(sort_param).not_to have_key('description')
    end
  end

  # ============================================
  # Swagger 2.0 (overrides still work)
  # ============================================
  describe 'Swagger 2.0' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'List'
        params do
          optional :page, type: Integer, documentation: {
            ref: '#/parameters/PageParam',
            ref_description: 'Page number override'
          }
        end
        get '/list' do
          []
        end

        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes overrides in Swagger 2.0' do
      params = subject['paths']['/list']['get']['parameters']
      page_param = params.find { |p| p['$ref'] }

      expect(page_param['$ref']).to eq('#/parameters/PageParam')
      expect(page_param['description']).to eq('Page number override')
    end
  end
end
