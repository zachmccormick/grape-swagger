# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::ComponentsBuilder do
  describe '.build' do
    context 'with empty components' do
      it 'returns empty components object' do
        components = described_class.build({})
        expect(components).to eq({})
      end
    end

    context 'with definitions (legacy)' do
      it 'moves definitions to components.schemas' do
        options = {
          definitions: {
            'User' => {
              type: 'object',
              properties: {
                id: { type: 'integer' },
                name: { type: 'string' }
              }
            },
            'Post' => {
              type: 'object',
              properties: {
                title: { type: 'string' }
              }
            }
          }
        }
        components = described_class.build(options)

        expect(components).to have_key(:schemas)
        expect(components[:schemas]).to have_key('User')
        expect(components[:schemas]).to have_key('Post')
        expect(components[:schemas]['User'][:type]).to eq('object')
        expect(components[:schemas]['User'][:properties][:name][:type]).to eq('string')
      end

      it 'does not include definitions key' do
        options = {
          definitions: { 'User' => { type: 'object' } }
        }
        components = described_class.build(options)

        expect(components).not_to have_key(:definitions)
      end
    end

    context 'with components.schemas directly' do
      it 'uses schemas as-is' do
        options = {
          components: {
            schemas: {
              'User' => { type: 'object' },
              'Post' => { type: 'object' }
            }
          }
        }
        components = described_class.build(options)

        expect(components[:schemas]).to have_key('User')
        expect(components[:schemas]).to have_key('Post')
      end
    end

    context 'with parameters' do
      it 'includes parameters in components' do
        options = {
          components: {
            parameters: {
              'PageParam' => {
                name: 'page',
                in: 'query',
                schema: { type: 'integer' }
              },
              'LimitParam' => {
                name: 'limit',
                in: 'query',
                schema: { type: 'integer' }
              }
            }
          }
        }
        components = described_class.build(options)

        expect(components[:parameters]).to have_key('PageParam')
        expect(components[:parameters]).to have_key('LimitParam')
        expect(components[:parameters]['PageParam'][:name]).to eq('page')
        expect(components[:parameters]['PageParam'][:in]).to eq('query')
      end
    end

    context 'with responses' do
      it 'includes responses in components' do
        options = {
          components: {
            responses: {
              'NotFound' => {
                description: 'Resource not found',
                content: {
                  'application/json' => {
                    schema: {
                      type: 'object',
                      properties: {
                        error: { type: 'string' }
                      }
                    }
                  }
                }
              },
              'Unauthorized' => {
                description: 'Unauthorized access'
              }
            }
          }
        }
        components = described_class.build(options)

        expect(components[:responses]).to have_key('NotFound')
        expect(components[:responses]).to have_key('Unauthorized')
        expect(components[:responses]['NotFound'][:description]).to eq('Resource not found')
      end
    end

    context 'with securitySchemes' do
      it 'includes security schemes in components' do
        options = {
          components: {
            securitySchemes: {
              'BearerAuth' => {
                type: 'http',
                scheme: 'bearer',
                bearerFormat: 'JWT'
              },
              'ApiKeyAuth' => {
                type: 'apiKey',
                in: 'header',
                name: 'X-API-Key'
              }
            }
          }
        }
        components = described_class.build(options)

        expect(components[:securitySchemes]).to have_key('BearerAuth')
        expect(components[:securitySchemes]).to have_key('ApiKeyAuth')
        expect(components[:securitySchemes]['BearerAuth'][:type]).to eq('http')
        expect(components[:securitySchemes]['BearerAuth'][:scheme]).to eq('bearer')
        expect(components[:securitySchemes]['ApiKeyAuth'][:type]).to eq('apiKey')
      end
    end

    context 'with legacy securityDefinitions' do
      it 'moves securityDefinitions to components.securitySchemes' do
        options = {
          securityDefinitions: {
            'api_key' => {
              type: 'apiKey',
              name: 'api_key',
              in: 'header'
            }
          }
        }
        components = described_class.build(options)

        expect(components[:securitySchemes]).to have_key('api_key')
        expect(components[:securitySchemes]['api_key'][:type]).to eq('apiKey')
        expect(components).not_to have_key(:securityDefinitions)
      end
    end

    context 'with all component types' do
      it 'builds complete components object' do
        options = {
          definitions: { 'User' => { type: 'object' } },
          components: {
            parameters: { 'PageParam' => { name: 'page' } },
            responses: { 'NotFound' => { description: 'Not found' } },
            securitySchemes: { 'BearerAuth' => { type: 'http' } }
          }
        }
        components = described_class.build(options)

        expect(components).to have_key(:schemas)
        expect(components).to have_key(:parameters)
        expect(components).to have_key(:responses)
        expect(components).to have_key(:securitySchemes)
      end
    end

    context 'with examples' do
      it 'includes examples in components' do
        options = {
          components: {
            examples: {
              'UserExample' => {
                value: {
                  id: 1,
                  name: 'John Doe'
                }
              }
            }
          }
        }
        components = described_class.build(options)

        expect(components[:examples]).to have_key('UserExample')
        expect(components[:examples]['UserExample'][:value][:name]).to eq('John Doe')
      end
    end

    context 'with requestBodies' do
      it 'includes requestBodies in components' do
        options = {
          components: {
            requestBodies: {
              'UserBody' => {
                description: 'User object',
                required: true,
                content: {
                  'application/json' => {
                    schema: { '$ref' => '#/components/schemas/User' }
                  }
                }
              }
            }
          }
        }
        components = described_class.build(options)

        expect(components[:requestBodies]).to have_key('UserBody')
        expect(components[:requestBodies]['UserBody'][:required]).to be true
      end
    end

    context 'with headers' do
      it 'includes headers in components' do
        options = {
          components: {
            headers: {
              'X-Rate-Limit' => {
                description: 'Rate limit header',
                schema: { type: 'integer' }
              }
            }
          }
        }
        components = described_class.build(options)

        expect(components[:headers]).to have_key('X-Rate-Limit')
        expect(components[:headers]['X-Rate-Limit'][:description]).to eq('Rate limit header')
      end
    end

    context 'precedence of components fields' do
      it 'prefers components.schemas over definitions' do
        options = {
          definitions: { 'User' => { type: 'object', description: 'old' } },
          components: {
            schemas: { 'User' => { type: 'object', description: 'new' } }
          }
        }
        components = described_class.build(options)

        expect(components[:schemas]['User'][:description]).to eq('new')
      end

      it 'prefers components.securitySchemes over securityDefinitions' do
        options = {
          securityDefinitions: { 'api_key' => { type: 'apiKey', name: 'old' } },
          components: {
            securitySchemes: { 'api_key' => { type: 'apiKey', name: 'new' } }
          }
        }
        components = described_class.build(options)

        expect(components[:securitySchemes]['api_key'][:name]).to eq('new')
      end
    end

    context 'with security scheme transformation' do
      let(:swagger_version) { GrapeSwagger::OpenAPI::Version.new(GrapeSwagger::OpenAPI::VersionConstants::SWAGGER_2_0) }
      let(:openapi_version) { GrapeSwagger::OpenAPI::Version.new(GrapeSwagger::OpenAPI::VersionConstants::OPENAPI_3_1_0) }

      it 'transforms OAuth2 security schemes for OpenAPI 3.1.0' do
        options = {
          securityDefinitions: {
            'oauth2' => {
              type: 'oauth2',
              flows: {
                authorizationCode: {
                  authorization_url: 'https://auth.example.com/authorize',
                  token_url: 'https://auth.example.com/token',
                  scopes: { 'read' => 'Read access' }
                }
              }
            }
          },
          version: openapi_version
        }
        components = described_class.build(options)

        expect(components[:securitySchemes]['oauth2'][:type]).to eq('oauth2')
        expect(components[:securitySchemes]['oauth2'][:flows][:authorizationCode]).to be_a(Hash)
        expect(components[:securitySchemes]['oauth2'][:flows][:authorizationCode][:authorizationUrl]).to eq('https://auth.example.com/authorize')
        expect(components[:securitySchemes]['oauth2'][:flows][:authorizationCode][:tokenUrl]).to eq('https://auth.example.com/token')
      end

      it 'transforms OpenID Connect security schemes for OpenAPI 3.1.0' do
        options = {
          securityDefinitions: {
            'openId' => {
              type: 'openIdConnect',
              openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
            }
          },
          version: openapi_version
        }
        components = described_class.build(options)

        expect(components[:securitySchemes]['openId'][:type]).to eq('openIdConnect')
        expect(components[:securitySchemes]['openId'][:openIdConnectUrl]).to eq('https://auth.example.com/.well-known/openid-configuration')
      end

      it 'transforms Mutual TLS security schemes for OpenAPI 3.1.0' do
        options = {
          securityDefinitions: {
            'mtls' => {
              type: 'mutualTLS',
              description: 'Client certificate required'
            }
          },
          version: openapi_version
        }
        components = described_class.build(options)

        expect(components[:securitySchemes]['mtls'][:type]).to eq('mutualTLS')
        expect(components[:securitySchemes]['mtls'][:description]).to eq('Client certificate required')
      end

      it 'converts OAuth2 to Swagger 2.0 format' do
        options = {
          securityDefinitions: {
            'oauth2' => {
              type: 'oauth2',
              flows: {
                authorizationCode: {
                  authorization_url: 'https://auth.example.com/authorize',
                  token_url: 'https://auth.example.com/token',
                  scopes: { 'read' => 'Read access' }
                }
              }
            }
          },
          version: swagger_version
        }
        components = described_class.build(options)

        expect(components[:securitySchemes]['oauth2'][:type]).to eq('oauth2')
        expect(components[:securitySchemes]['oauth2'][:flow]).to eq('accessCode')
        expect(components[:securitySchemes]['oauth2'][:authorizationUrl]).to eq('https://auth.example.com/authorize')
        expect(components[:securitySchemes]['oauth2'][:tokenUrl]).to eq('https://auth.example.com/token')
        expect(components[:securitySchemes]['oauth2'][:flows]).to be_nil
      end

      it 'filters out unsupported security schemes for Swagger 2.0' do
        options = {
          securityDefinitions: {
            'openId' => {
              type: 'openIdConnect',
              openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
            },
            'mtls' => {
              type: 'mutualTLS'
            },
            'api_key' => {
              type: 'apiKey',
              name: 'X-API-Key',
              in: 'header'
            }
          },
          version: swagger_version
        }
        components = described_class.build(options)

        # openId and mtls should be filtered out for Swagger 2.0
        expect(components[:securitySchemes].key?('openId')).to be(false)
        expect(components[:securitySchemes].key?('mtls')).to be(false)
        # api_key should remain
        expect(components[:securitySchemes].key?('api_key')).to be(true)
      end
    end

    context 'with version-aware reference translation' do
      let(:swagger_version) { GrapeSwagger::OpenAPI::Version.new(GrapeSwagger::OpenAPI::VersionConstants::SWAGGER_2_0) }
      let(:openapi_version) { GrapeSwagger::OpenAPI::Version.new(GrapeSwagger::OpenAPI::VersionConstants::OPENAPI_3_1_0) }

      it 'does not translate references for Swagger 2.0' do
        options = {
          definitions: {
            'User' => {
              type: 'object',
              properties: {
                profile: { '$ref' => '#/definitions/Profile' }
              }
            },
            'Profile' => { type: 'object' }
          },
          version: swagger_version
        }
        components = described_class.build(options)

        expect(components[:schemas]['User'][:properties][:profile]['$ref']).to eq('#/definitions/Profile')
      end

      it 'translates references for OpenAPI 3.1.0' do
        options = {
          definitions: {
            'User' => {
              type: 'object',
              properties: {
                profile: { '$ref' => '#/definitions/Profile' }
              }
            },
            'Profile' => { type: 'object' }
          },
          version: openapi_version
        }
        components = described_class.build(options)

        expect(components[:schemas]['User'][:properties][:profile]['$ref']).to eq('#/components/schemas/Profile')
      end

      it 'translates nested references for OpenAPI 3.1.0' do
        options = {
          definitions: {
            'User' => {
              type: 'object',
              properties: {
                profile: { '$ref' => '#/definitions/Profile' },
                account: { '$ref' => '#/definitions/Account' }
              }
            }
          },
          version: openapi_version
        }
        components = described_class.build(options)

        expect(components[:schemas]['User'][:properties][:profile]['$ref']).to eq('#/components/schemas/Profile')
        expect(components[:schemas]['User'][:properties][:account]['$ref']).to eq('#/components/schemas/Account')
      end

      it 'translates array item references for OpenAPI 3.1.0' do
        options = {
          definitions: {
            'UserList' => {
              type: 'array',
              items: { '$ref' => '#/definitions/User' }
            }
          },
          version: openapi_version
        }
        components = described_class.build(options)

        expect(components[:schemas]['UserList'][:items]['$ref']).to eq('#/components/schemas/User')
      end

      it 'translates allOf references for OpenAPI 3.1.0' do
        options = {
          definitions: {
            'ExtendedUser' => {
              allOf: [
                { '$ref' => '#/definitions/BaseUser' },
                { type: 'object', properties: { extended: { type: 'boolean' } } }
              ]
            }
          },
          version: openapi_version
        }
        components = described_class.build(options)

        expect(components[:schemas]['ExtendedUser'][:allOf][0]['$ref']).to eq('#/components/schemas/BaseUser')
      end
    end
  end
end
