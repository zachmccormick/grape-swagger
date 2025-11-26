# frozen_string_literal: true

require 'spec_helper'

describe 'Security Scheme Integration' do
  def app
    Class.new(Grape::API) do
      format :json

      # Public endpoint (no security)
      desc 'Public endpoint', security: []
      get '/public' do
        { message: 'public' }
      end

      # API Key protected endpoint
      desc 'API Key protected', security: [{ api_key: [] }]
      get '/api_key' do
        { message: 'api key required' }
      end

      # OAuth2 protected endpoint
      desc 'OAuth2 protected', security: [{ oauth2: ['read', 'write'] }]
      get '/oauth2' do
        { message: 'oauth2 required' }
      end

      # OpenID Connect protected endpoint
      desc 'OpenID Connect protected', security: [{ openId: [] }]
      get '/openid' do
        { message: 'openid required' }
      end

      # Mutual TLS protected endpoint
      desc 'Mutual TLS protected', security: [{ mtls: [] }]
      get '/mtls' do
        { message: 'mtls required' }
      end

      # Multiple security schemes (AND)
      desc 'Multiple schemes required', security: [{ api_key: [], oauth2: ['read'] }]
      get '/multiple_and' do
        { message: 'multiple required' }
      end

      # Alternative security schemes (OR)
      desc 'Alternative schemes', security: [{ api_key: [] }, { oauth2: ['read'] }]
      get '/multiple_or' do
        { message: 'alternative schemes' }
      end

      add_swagger_documentation(
        openapi_version: '3.1.0',
        security_definitions: {
          api_key: {
            type: 'apiKey',
            name: 'X-API-Key',
            in: 'header',
            description: 'API key authentication'
          },
          oauth2: {
            type: 'oauth2',
            description: 'OAuth2 authentication',
            flows: {
              authorizationCode: {
                authorization_url: 'https://auth.example.com/authorize',
                token_url: 'https://auth.example.com/token',
                refresh_url: 'https://auth.example.com/refresh',
                scopes: {
                  'read' => 'Read access to resources',
                  'write' => 'Write access to resources',
                  'admin' => 'Admin access to all resources'
                }
              },
              clientCredentials: {
                token_url: 'https://auth.example.com/token',
                scopes: {
                  'api' => 'API access'
                }
              }
            }
          },
          openId: {
            type: 'openIdConnect',
            description: 'OpenID Connect authentication',
            openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
          },
          mtls: {
            type: 'mutualTLS',
            description: 'Client certificate authentication required'
          }
        },
        security: [
          { oauth2: ['read'] }
        ]
      )
    end
  end

  subject do
    get '/swagger_doc.json'
    JSON.parse(last_response.body)
  end

  describe 'OpenAPI 3.1.0 format' do
    it 'includes openapi version' do
      expect(subject['openapi']).to eq('3.1.0')
    end

    describe 'security schemes' do
      let(:security_schemes) { subject['components']['securitySchemes'] }

      it 'includes all security schemes' do
        expect(security_schemes).to have_key('api_key')
        expect(security_schemes).to have_key('oauth2')
        expect(security_schemes).to have_key('openId')
        expect(security_schemes).to have_key('mtls')
      end

      it 'formats API key scheme correctly' do
        expect(security_schemes['api_key']['type']).to eq('apiKey')
        expect(security_schemes['api_key']['name']).to eq('X-API-Key')
        expect(security_schemes['api_key']['in']).to eq('header')
        expect(security_schemes['api_key']['description']).to eq('API key authentication')
      end

      it 'formats OAuth2 scheme correctly' do
        oauth2 = security_schemes['oauth2']
        expect(oauth2['type']).to eq('oauth2')
        expect(oauth2['description']).to eq('OAuth2 authentication')
        expect(oauth2['flows']).to be_a(Hash)
        expect(oauth2['flows']).to have_key('authorizationCode')
        expect(oauth2['flows']).to have_key('clientCredentials')
      end

      it 'includes OAuth2 authorizationCode flow details' do
        flow = security_schemes['oauth2']['flows']['authorizationCode']
        expect(flow['authorizationUrl']).to eq('https://auth.example.com/authorize')
        expect(flow['tokenUrl']).to eq('https://auth.example.com/token')
        expect(flow['refreshUrl']).to eq('https://auth.example.com/refresh')
        expect(flow['scopes']).to be_a(Hash)
        expect(flow['scopes']['read']).to eq('Read access to resources')
        expect(flow['scopes']['write']).to eq('Write access to resources')
        expect(flow['scopes']['admin']).to eq('Admin access to all resources')
      end

      it 'includes OAuth2 clientCredentials flow details' do
        flow = security_schemes['oauth2']['flows']['clientCredentials']
        expect(flow['tokenUrl']).to eq('https://auth.example.com/token')
        expect(flow['scopes']).to be_a(Hash)
        expect(flow['scopes']['api']).to eq('API access')
        expect(flow['authorizationUrl']).to be_nil
      end

      it 'formats OpenID Connect scheme correctly' do
        openid = security_schemes['openId']
        expect(openid['type']).to eq('openIdConnect')
        expect(openid['description']).to eq('OpenID Connect authentication')
        expect(openid['openIdConnectUrl']).to eq('https://auth.example.com/.well-known/openid-configuration')
      end

      it 'formats Mutual TLS scheme correctly' do
        mtls = security_schemes['mtls']
        expect(mtls['type']).to eq('mutualTLS')
        expect(mtls['description']).to eq('Client certificate authentication required')
      end
    end

    describe 'global security' do
      it 'includes global security requirement' do
        expect(subject['security']).to be_an(Array)
        expect(subject['security']).to include({ 'oauth2' => ['read'] })
      end
    end

    describe 'endpoint security' do
      let(:paths) { subject['paths'] }

      it 'marks public endpoint with empty security' do
        expect(paths['/public']['get']['security']).to eq([])
      end

      it 'includes API key security on protected endpoint' do
        expect(paths['/api_key']['get']['security']).to eq([{ 'api_key' => [] }])
      end

      it 'includes OAuth2 security with scopes' do
        expect(paths['/oauth2']['get']['security']).to eq([{ 'oauth2' => ['read', 'write'] }])
      end

      it 'includes OpenID Connect security' do
        expect(paths['/openid']['get']['security']).to eq([{ 'openId' => [] }])
      end

      it 'includes Mutual TLS security' do
        expect(paths['/mtls']['get']['security']).to eq([{ 'mtls' => [] }])
      end

      it 'supports AND combination (multiple schemes required)' do
        security = paths['/multiple_and']['get']['security']
        expect(security).to eq([{ 'api_key' => [], 'oauth2' => ['read'] }])
      end

      it 'supports OR combination (alternative schemes)' do
        security = paths['/multiple_or']['get']['security']
        expect(security).to eq([{ 'api_key' => [] }, { 'oauth2' => ['read'] }])
      end
    end
  end
end

describe 'Security Scheme Swagger 2.0 Compatibility' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'OAuth2 protected', security: [{ oauth2: ['read'] }]
      get '/oauth2' do
        { message: 'oauth2' }
      end

      desc 'API Key protected', security: [{ api_key: [] }]
      get '/api_key' do
        { message: 'api_key' }
      end

      add_swagger_documentation(
        security_definitions: {
          oauth2: {
            type: 'oauth2',
            flows: {
              authorizationCode: {
                authorization_url: 'https://auth.example.com/authorize',
                token_url: 'https://auth.example.com/token',
                scopes: { 'read' => 'Read access' }
              }
            }
          },
          api_key: {
            type: 'apiKey',
            name: 'X-API-Key',
            in: 'header'
          },
          openId: {
            type: 'openIdConnect',
            openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
          },
          mtls: {
            type: 'mutualTLS'
          }
        }
      )
    end
  end

  subject do
    get '/swagger_doc.json'
    JSON.parse(last_response.body)
  end

  it 'uses Swagger 2.0 format' do
    expect(subject['swagger']).to eq('2.0')
  end

  describe 'security definitions' do
    let(:security_defs) { subject['securityDefinitions'] }

    it 'converts OAuth2 to Swagger 2.0 format' do
      oauth2 = security_defs['oauth2']
      expect(oauth2['type']).to eq('oauth2')
      expect(oauth2['flow']).to eq('accessCode')
      expect(oauth2['authorizationUrl']).to eq('https://auth.example.com/authorize')
      expect(oauth2['tokenUrl']).to eq('https://auth.example.com/token')
      expect(oauth2['scopes']).to eq({ 'read' => 'Read access' })
      expect(oauth2['flows']).to be_nil
    end

    it 'includes API key scheme' do
      api_key = security_defs['api_key']
      expect(api_key['type']).to eq('apiKey')
      expect(api_key['name']).to eq('X-API-Key')
      expect(api_key['in']).to eq('header')
    end

    it 'filters out OpenID Connect (not supported in Swagger 2.0)' do
      expect(security_defs).not_to have_key('openId')
    end

    it 'filters out Mutual TLS (not supported in Swagger 2.0)' do
      expect(security_defs).not_to have_key('mtls')
    end
  end
end
