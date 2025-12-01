# frozen_string_literal: true

require 'spec_helper'

describe 'Path-Level Parameters' do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  describe 'path_params DSL' do
    let(:app) do
      Class.new(Grape::API) do
        namespace :users do
          path_params do
            requires :user_id, type: Integer, desc: 'User ID'
          end

          route_param :user_id do
            get do
              { user_id: params[:user_id] }
            end

            put do
              { user_id: params[:user_id] }
            end
          end
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'places parameters at path level, not duplicated per operation' do
      path_item = subject['paths']['/users/{user_id}']

      # Parameters should be at path level
      expect(path_item['parameters']).to be_an(Array)
      expect(path_item['parameters'].length).to eq(1)

      param = path_item['parameters'].first
      expect(param['name']).to eq('user_id')
      expect(param['in']).to eq('path')
      expect(param['required']).to eq(true)

      # GET and PUT should NOT have the user_id parameter duplicated
      expect(path_item['get']['parameters']).to be_nil
      expect(path_item['put']['parameters']).to be_nil
    end
  end
end
