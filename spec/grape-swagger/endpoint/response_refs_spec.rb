# frozen_string_literal: true

require 'spec_helper'

describe 'Response reference support' do
  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
  end

  let(:app) do
    # Define reusable response
    Class.new(GrapeSwagger::ReusableResponse) do
      def self.name
        'RefTestNotFound'
      end

      description 'Resource not found'
      json_schema({ type: 'object', properties: { error: { type: 'string' } } })
    end

    Class.new(GrapeSwagger::ReusableResponse) do
      def self.name
        'RefTestUnauthorized'
      end

      description 'Authentication required'
      json_schema({ type: 'object', properties: { message: { type: 'string' } } })
    end

    Class.new(Grape::API) do
      format :json

      desc 'Get item',
           success: { code: 200, message: 'Success' },
           failure: [
             { code: 404, model: :RefTestNotFound },
             { code: 401, model: :RefTestUnauthorized }
           ]
      get '/items/:id' do
        { id: params[:id] }
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it 'generates $ref for symbol model references' do
    responses = subject['paths']['/items/{id}']['get']['responses']

    expect(responses['404']).to eq({ '$ref' => '#/components/responses/RefTestNotFound' })
    expect(responses['401']).to eq({ '$ref' => '#/components/responses/RefTestUnauthorized' })
  end

  it 'includes referenced responses in components' do
    expect(subject['components']['responses']).to have_key('RefTestNotFound')
    expect(subject['components']['responses']['RefTestNotFound']['description']).to eq('Resource not found')
  end
end
