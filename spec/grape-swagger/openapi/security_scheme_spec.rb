# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 Security Schemes' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get items'
      get '/items' do
        []
      end

      add_swagger_documentation(
        openapi_version: '3.1.0',
        security_definitions: {
          mutual_tls: {
            type: 'mutualTLS',
            description: 'Client certificate authentication'
          },
          openid_connect: {
            type: 'openIdConnect',
            openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
          },
          api_key: {
            type: 'apiKey',
            name: 'X-API-Key',
            in: 'header'
          }
        }
      )
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:security_schemes) { subject.dig('components', 'securitySchemes') }

  describe 'BUG-010: mutualTLS format' do
    it 'includes mutualTLS in security schemes' do
      expect(security_schemes).to have_key('mutual_tls')
    end

    it 'has correct type for mutualTLS' do
      scheme = security_schemes['mutual_tls']
      expect(scheme['type']).to eq('mutualTLS')
    end

    it 'includes description for mutualTLS' do
      scheme = security_schemes['mutual_tls']
      expect(scheme['description']).to eq('Client certificate authentication')
    end
  end

  describe 'OpenID Connect scheme' do
    it 'has correct type for openIdConnect' do
      scheme = security_schemes['openid_connect']
      expect(scheme['type']).to eq('openIdConnect')
    end

    it 'includes openIdConnectUrl' do
      scheme = security_schemes['openid_connect']
      expect(scheme['openIdConnectUrl']).to eq('https://auth.example.com/.well-known/openid-configuration')
    end
  end

  describe 'API Key scheme' do
    it 'has correct type for apiKey' do
      scheme = security_schemes['api_key']
      expect(scheme['type']).to eq('apiKey')
    end

    it 'includes name and in' do
      scheme = security_schemes['api_key']
      expect(scheme['name']).to eq('X-API-Key')
      expect(scheme['in']).to eq('header')
    end
  end
end
