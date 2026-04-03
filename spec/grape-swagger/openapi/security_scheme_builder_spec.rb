# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::SecuritySchemeBuilder do
  describe '.build' do
    context 'OAuth2 flows' do
      context 'authorizationCode flow' do
        it 'builds OAuth2 with authorizationCode flow' do
          config = {
            type: 'oauth2',
            description: 'OAuth2 authentication',
            flows: {
              authorizationCode: {
                authorization_url: 'https://auth.example.com/authorize',
                token_url: 'https://auth.example.com/token',
                scopes: {
                  'read' => 'Read access',
                  'write' => 'Write access'
                }
              }
            }
          }

          result = described_class.build(config)

          expect(result[:type]).to eq('oauth2')
          expect(result[:description]).to eq('OAuth2 authentication')
          expect(result[:flows][:authorizationCode]).to be_a(Hash)
          expect(result[:flows][:authorizationCode][:authorizationUrl]).to eq('https://auth.example.com/authorize')
          expect(result[:flows][:authorizationCode][:tokenUrl]).to eq('https://auth.example.com/token')
          expect(result[:flows][:authorizationCode][:scopes]).to eq({
            'read' => 'Read access',
            'write' => 'Write access'
          })
        end

        it 'includes refreshUrl when provided' do
          config = {
            type: 'oauth2',
            flows: {
              authorizationCode: {
                authorization_url: 'https://auth.example.com/authorize',
                token_url: 'https://auth.example.com/token',
                refresh_url: 'https://auth.example.com/refresh',
                scopes: {}
              }
            }
          }

          result = described_class.build(config)

          expect(result[:flows][:authorizationCode][:refreshUrl]).to eq('https://auth.example.com/refresh')
        end
      end

      context 'clientCredentials flow' do
        it 'builds OAuth2 with clientCredentials flow' do
          config = {
            type: 'oauth2',
            description: 'Client credentials flow',
            flows: {
              clientCredentials: {
                token_url: 'https://auth.example.com/token',
                scopes: {
                  'api' => 'API access'
                }
              }
            }
          }

          result = described_class.build(config)

          expect(result[:type]).to eq('oauth2')
          expect(result[:flows][:clientCredentials]).to be_a(Hash)
          expect(result[:flows][:clientCredentials][:tokenUrl]).to eq('https://auth.example.com/token')
          expect(result[:flows][:clientCredentials][:scopes]).to eq({ 'api' => 'API access' })
          expect(result[:flows][:clientCredentials][:authorizationUrl]).to be_nil
        end
      end

      context 'implicit flow (deprecated)' do
        it 'builds OAuth2 with implicit flow' do
          config = {
            type: 'oauth2',
            description: 'Implicit flow (deprecated)',
            flows: {
              implicit: {
                authorization_url: 'https://auth.example.com/authorize',
                scopes: {
                  'read' => 'Read access'
                }
              }
            }
          }

          result = described_class.build(config)

          expect(result[:type]).to eq('oauth2')
          expect(result[:flows][:implicit]).to be_a(Hash)
          expect(result[:flows][:implicit][:authorizationUrl]).to eq('https://auth.example.com/authorize')
          expect(result[:flows][:implicit][:scopes]).to eq({ 'read' => 'Read access' })
          expect(result[:flows][:implicit][:tokenUrl]).to be_nil
        end
      end

      context 'password flow (deprecated)' do
        it 'builds OAuth2 with password flow' do
          config = {
            type: 'oauth2',
            description: 'Password flow (deprecated)',
            flows: {
              password: {
                token_url: 'https://auth.example.com/token',
                scopes: {
                  'user' => 'User access'
                }
              }
            }
          }

          result = described_class.build(config)

          expect(result[:type]).to eq('oauth2')
          expect(result[:flows][:password]).to be_a(Hash)
          expect(result[:flows][:password][:tokenUrl]).to eq('https://auth.example.com/token')
          expect(result[:flows][:password][:scopes]).to eq({ 'user' => 'User access' })
        end
      end

      context 'multiple flows' do
        it 'builds OAuth2 with multiple flows' do
          config = {
            type: 'oauth2',
            description: 'OAuth2 with multiple flows',
            flows: {
              authorizationCode: {
                authorization_url: 'https://auth.example.com/authorize',
                token_url: 'https://auth.example.com/token',
                scopes: { 'read' => 'Read' }
              },
              clientCredentials: {
                token_url: 'https://auth.example.com/token',
                scopes: { 'api' => 'API' }
              }
            }
          }

          result = described_class.build(config)

          expect(result[:flows].keys).to contain_exactly(:authorizationCode, :clientCredentials)
          expect(result[:flows][:authorizationCode]).to be_a(Hash)
          expect(result[:flows][:clientCredentials]).to be_a(Hash)
        end
      end

      context 'scopes' do
        it 'handles empty scopes' do
          config = {
            type: 'oauth2',
            flows: {
              authorizationCode: {
                authorization_url: 'https://auth.example.com/authorize',
                token_url: 'https://auth.example.com/token',
                scopes: {}
              }
            }
          }

          result = described_class.build(config)

          expect(result[:flows][:authorizationCode][:scopes]).to eq({})
        end

        it 'handles multiple scopes with descriptions' do
          config = {
            type: 'oauth2',
            flows: {
              authorizationCode: {
                authorization_url: 'https://auth.example.com/authorize',
                token_url: 'https://auth.example.com/token',
                scopes: {
                  'read' => 'Read access to resources',
                  'write' => 'Write access to resources',
                  'admin' => 'Admin access to all resources',
                  'delete' => 'Delete resources'
                }
              }
            }
          }

          result = described_class.build(config)

          expect(result[:flows][:authorizationCode][:scopes].size).to eq(4)
          expect(result[:flows][:authorizationCode][:scopes]['admin']).to eq('Admin access to all resources')
        end
      end
    end

    context 'OpenID Connect' do
      it 'builds openIdConnect security scheme' do
        config = {
          type: 'openIdConnect',
          description: 'OpenID Connect authentication',
          openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
        }

        result = described_class.build(config)

        expect(result[:type]).to eq('openIdConnect')
        expect(result[:description]).to eq('OpenID Connect authentication')
        expect(result[:openIdConnectUrl]).to eq('https://auth.example.com/.well-known/openid-configuration')
      end

      it 'builds openIdConnect without description' do
        config = {
          type: 'openIdConnect',
          openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
        }

        result = described_class.build(config)

        expect(result[:type]).to eq('openIdConnect')
        expect(result[:openIdConnectUrl]).to eq('https://auth.example.com/.well-known/openid-configuration')
        expect(result[:description]).to be_nil
      end
    end

    context 'Mutual TLS' do
      it 'builds mutualTLS security scheme' do
        config = {
          type: 'mutualTLS',
          description: 'Client certificate authentication required'
        }

        result = described_class.build(config)

        expect(result[:type]).to eq('mutualTLS')
        expect(result[:description]).to eq('Client certificate authentication required')
      end

      it 'builds mutualTLS without description' do
        config = {
          type: 'mutualTLS'
        }

        result = described_class.build(config)

        expect(result[:type]).to eq('mutualTLS')
        expect(result[:description]).to be_nil
      end
    end

    context 'Basic auth and API key schemes' do
      it 'builds http basic scheme' do
        config = {
          type: 'http',
          scheme: 'basic',
          description: 'Basic authentication'
        }

        result = described_class.build(config)

        expect(result[:type]).to eq('http')
        expect(result[:scheme]).to eq('basic')
        expect(result[:description]).to eq('Basic authentication')
      end

      it 'builds http bearer scheme' do
        config = {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Bearer token authentication'
        }

        result = described_class.build(config)

        expect(result[:type]).to eq('http')
        expect(result[:scheme]).to eq('bearer')
        expect(result[:bearerFormat]).to eq('JWT')
        expect(result[:description]).to eq('Bearer token authentication')
      end

      it 'builds apiKey scheme' do
        config = {
          type: 'apiKey',
          name: 'X-API-Key',
          in: 'header',
          description: 'API key authentication'
        }

        result = described_class.build(config)

        expect(result[:type]).to eq('apiKey')
        expect(result[:name]).to eq('X-API-Key')
        expect(result[:in]).to eq('header')
        expect(result[:description]).to eq('API key authentication')
      end
    end

    context 'compact output' do
      it 'omits nil values' do
        config = {
          type: 'oauth2',
          flows: {
            authorizationCode: {
              authorization_url: 'https://auth.example.com/authorize',
              token_url: 'https://auth.example.com/token',
              scopes: {}
            }
          }
        }

        result = described_class.build(config)

        expect(result[:flows][:authorizationCode].key?(:refreshUrl)).to be(false)
        expect(result.key?(:description)).to be(false)
      end
    end

    context 'edge cases' do
      it 'handles nil config' do
        expect(described_class.build(nil)).to eq({})
      end

      it 'handles empty config' do
        result = described_class.build({})
        expect(result).to eq({})
      end

      it 'handles unknown type' do
        config = { type: 'unknown' }
        result = described_class.build(config)
        expect(result[:type]).to eq('unknown')
      end

      it 'handles invalid flow names' do
        config = {
          type: 'oauth2',
          flows: {
            invalidFlow: {
              authorization_url: 'https://auth.example.com/authorize',
              scopes: {}
            }
          }
        }

        result = described_class.build(config)

        expect(result[:flows].key?(:invalidFlow)).to be(false)
      end
    end
  end
end
