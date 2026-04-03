# frozen_string_literal: true

require 'spec_helper'

describe 'Parameter examples map (OpenAPI 3.1.0)' do
  describe 'parameter with named examples' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items with examples'
        params do
          optional :status, type: String, documentation: {
            desc: 'Item status filter',
            examples: {
              active: {
                summary: 'Active items',
                value: 'active'
              },
              archived: {
                summary: 'Archived items',
                value: 'archived'
              }
            }
          }
        end
        get :items do
          { items: [] }
        end

        add_swagger_documentation(openapi_version: '3.1.0')
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes examples map on the parameter' do
      param = subject['paths']['/items']['get']['parameters'].find { |p| p['name'] == 'status' }
      expect(param['examples']).to be_a(Hash)
      expect(param['examples']['active']['summary']).to eq('Active items')
      expect(param['examples']['active']['value']).to eq('active')
      expect(param['examples']['archived']['summary']).to eq('Archived items')
    end
  end
end
