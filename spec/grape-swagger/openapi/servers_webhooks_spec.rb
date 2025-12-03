# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 Servers and Webhooks' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get items'
      get '/items' do
        []
      end

      add_swagger_documentation(
        openapi_version: '3.1.0',
        servers: [
          { url: 'https://api.example.com/v1', description: 'Production' },
          { url: 'https://staging.example.com/v1', description: 'Staging' }
        ],
        webhooks: {
          orderCreated: {
            method: :post,
            summary: 'Order created notification',
            request: { schema: { type: 'object' } }
          }
        }
      )
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'BUG-007: Servers array should be output' do
    it 'includes servers array' do
      expect(subject).to have_key('servers')
    end

    it 'has correct server entries' do
      servers = subject['servers']
      expect(servers.size).to eq(2)
      expect(servers.first['url']).to eq('https://api.example.com/v1')
      expect(servers.first['description']).to eq('Production')
    end
  end

  describe 'BUG-008: Webhooks should be output' do
    it 'includes webhooks object' do
      expect(subject).to have_key('webhooks')
    end

    it 'has the defined webhook' do
      webhooks = subject['webhooks']
      expect(webhooks).to have_key('orderCreated')
    end
  end
end
