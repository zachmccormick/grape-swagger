# frozen_string_literal: true

require 'spec_helper'

describe 'Sprint 2: Core Structural Components Integration' do
  describe 'Building complete OpenAPI 3.1.0 specification' do
    let(:swagger_2_0_options) do
      {
        openapi_version: '2.0',
        info: {
          title: 'Legacy API',
          version: '1.0.0',
          description: 'A legacy Swagger 2.0 API'
        },
        host: 'api.example.com',
        base_path: '/v1',
        schemes: %w[https http],
        definitions: {
          'User' => {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              name: { type: 'string' },
              email: { type: 'string', format: 'email' }
            },
            required: %w[id name]
          },
          'Post' => {
            type: 'object',
            properties: {
              id: { type: 'integer' },
              title: { type: 'string' },
              content: { type: 'string' }
            }
          }
        },
        securityDefinitions: {
          'api_key' => {
            type: 'apiKey',
            name: 'X-API-Key',
            in: 'header'
          }
        }
      }
    end

    let(:openapi_3_1_0_options) do
      {
        openapi_version: '3.1.0',
        info: {
          title: 'Modern API',
          version: '2.0.0',
          description: 'A modern OpenAPI 3.1.0 API',
          contact: {
            name: 'API Support',
            email: 'support@example.com'
          },
          license: {
            name: 'MIT',
            url: 'https://opensource.org/licenses/MIT'
          }
        },
        servers: [
          {
            url: 'https://api.example.com/v2',
            description: 'Production server'
          },
          {
            url: 'https://staging.example.com/v2',
            description: 'Staging server'
          }
        ],
        paths: {
          '/users' => {
            get: {
              summary: 'List all users',
              tags: ['users'],
              responses: {
                '200' => {
                  description: 'Successful response',
                  content: {
                    'application/json' => {
                      schema: {
                        type: 'array',
                        items: { '$ref' => '#/components/schemas/User' }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        components: {
          schemas: {
            'User' => {
              type: 'object',
              properties: {
                id: { type: 'integer' },
                name: { type: 'string' },
                email: { type: 'string', format: 'email' }
              }
            }
          },
          securitySchemes: {
            'BearerAuth' => {
              type: 'http',
              scheme: 'bearer',
              bearerFormat: 'JWT'
            }
          }
        },
        security: [
          { 'BearerAuth' => [] }
        ],
        tags: [
          { name: 'users', description: 'User management endpoints' }
        ]
      }
    end

    context 'with OpenAPI 3.1.0 version' do
      it 'builds complete OpenAPI 3.1.0 specification' do
        spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(openapi_3_1_0_options)

        # Root structure
        expect(spec[:openapi]).to eq('3.1.0')
        expect(spec).not_to have_key(:swagger)

        # Info object
        expect(spec[:info][:title]).to eq('Modern API')
        expect(spec[:info][:version]).to eq('2.0.0')
        expect(spec[:info][:description]).to eq('A modern OpenAPI 3.1.0 API')
        expect(spec[:info][:contact][:email]).to eq('support@example.com')
        expect(spec[:info][:license][:name]).to eq('MIT')

        # Servers array
        expect(spec[:servers]).to be_an(Array)
        expect(spec[:servers].size).to eq(2)
        expect(spec[:servers][0][:url]).to eq('https://api.example.com/v2')
        expect(spec[:servers][1][:url]).to eq('https://staging.example.com/v2')

        # Paths
        expect(spec[:paths]).to have_key('/users')
        expect(spec[:paths]['/users'][:get][:summary]).to eq('List all users')

        # Components
        expect(spec[:components][:schemas]).to have_key('User')
        expect(spec[:components][:securitySchemes]).to have_key('BearerAuth')
        expect(spec[:components][:securitySchemes]['BearerAuth'][:type]).to eq('http')

        # Security
        expect(spec[:security]).to be_an(Array)
        expect(spec[:security][0]).to have_key('BearerAuth')

        # Tags
        expect(spec[:tags]).to be_an(Array)
        expect(spec[:tags][0][:name]).to eq('users')
      end
    end

    context 'converting Swagger 2.0 to OpenAPI 3.1.0' do
      it 'converts legacy format to OpenAPI 3.1.0 structure' do
        # Use SpecBuilderV3_1 with legacy options
        spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(swagger_2_0_options)

        # Should have OpenAPI 3.1.0 root
        expect(spec[:openapi]).to eq('3.1.0')
        expect(spec).not_to have_key(:swagger)

        # Info preserved
        expect(spec[:info][:title]).to eq('Legacy API')
        expect(spec[:info][:version]).to eq('1.0.0')

        # Legacy host/basePath/schemes converted to servers
        expect(spec[:servers]).to be_an(Array)
        expect(spec[:servers].size).to eq(2) # Two schemes
        expect(spec[:servers][0][:url]).to eq('https://api.example.com/v1')
        expect(spec[:servers][1][:url]).to eq('http://api.example.com/v1')

        # Legacy fields removed
        expect(spec).not_to have_key(:host)
        expect(spec).not_to have_key(:basePath)
        expect(spec).not_to have_key(:schemes)

        # Definitions converted to components.schemas
        expect(spec[:components][:schemas]).to have_key('User')
        expect(spec[:components][:schemas]).to have_key('Post')
        expect(spec[:components][:schemas]['User'][:type]).to eq('object')
        expect(spec).not_to have_key(:definitions)

        # SecurityDefinitions converted to components.securitySchemes
        expect(spec[:components][:securitySchemes]).to have_key('api_key')
        expect(spec[:components][:securitySchemes]['api_key'][:type]).to eq('apiKey')
        expect(spec).not_to have_key(:securityDefinitions)
      end
    end

    context 'VersionSelector integration' do
      it 'routes to correct builder based on version' do
        # Version 3.1.0
        version_3_1_0 = GrapeSwagger::OpenAPI::VersionSelector.build_spec(openapi_3_1_0_options)
        expect(version_3_1_0.version_string).to eq('3.1.0')
        expect(version_3_1_0.openapi_3_1_0?).to be true
        expect(version_3_1_0.swagger_2_0?).to be false

        # Version 2.0
        version_2_0 = GrapeSwagger::OpenAPI::VersionSelector.build_spec(swagger_2_0_options)
        expect(version_2_0.version_string).to eq('2.0')
        expect(version_2_0.swagger_2_0?).to be true
        expect(version_2_0.openapi_3_1_0?).to be false
      end
    end

    context 'with server variables' do
      let(:options_with_variables) do
        {
          openapi_version: '3.1.0',
          info: { title: 'API with Variables' },
          servers: [
            {
              url: 'https://{environment}.api.example.com/{version}',
              description: 'Multi-environment API',
              variables: {
                environment: {
                  default: 'production',
                  enum: %w[production staging development],
                  description: 'Environment name'
                },
                version: {
                  default: 'v2',
                  description: 'API version'
                }
              }
            }
          ]
        }
      end

      it 'preserves server variables in OpenAPI 3.1.0 spec' do
        spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(options_with_variables)

        server = spec[:servers][0]
        expect(server[:url]).to eq('https://{environment}.api.example.com/{version}')
        expect(server[:variables][:environment][:default]).to eq('production')
        expect(server[:variables][:environment][:enum]).to include('production', 'staging', 'development')
        expect(server[:variables][:version][:default]).to eq('v2')
      end
    end

    context 'with all component types' do
      let(:complete_components_options) do
        {
          openapi_version: '3.1.0',
          info: { title: 'Complete Components API' },
          components: {
            schemas: {
              'User' => { type: 'object' }
            },
            responses: {
              'NotFound' => {
                description: 'Resource not found'
              }
            },
            parameters: {
              'PageParam' => {
                name: 'page',
                in: 'query',
                schema: { type: 'integer' }
              }
            },
            examples: {
              'UserExample' => {
                value: { id: 1, name: 'John' }
              }
            },
            requestBodies: {
              'UserBody' => {
                required: true,
                content: {
                  'application/json' => {
                    schema: { '$ref' => '#/components/schemas/User' }
                  }
                }
              }
            },
            headers: {
              'X-Rate-Limit' => {
                schema: { type: 'integer' }
              }
            },
            securitySchemes: {
              'BearerAuth' => {
                type: 'http',
                scheme: 'bearer'
              }
            }
          }
        }
      end

      it 'includes all component types in the spec' do
        spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(complete_components_options)

        components = spec[:components]
        expect(components).to have_key(:schemas)
        expect(components).to have_key(:responses)
        expect(components).to have_key(:parameters)
        expect(components).to have_key(:examples)
        expect(components).to have_key(:requestBodies)
        expect(components).to have_key(:headers)
        expect(components).to have_key(:securitySchemes)
      end
    end
  end

  describe 'Story 2.1: OpenAPI Root Object' do
    it 'generates correct OpenAPI 3.1.0 root structure' do
      options = {
        info: { title: 'Test API', version: '1.0.0' },
        paths: { '/test' => { get: { summary: 'Test' } } }
      }

      spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(options)

      # AC: Root contains openapi: "3.1.0" instead of swagger: "2.0"
      expect(spec[:openapi]).to eq('3.1.0')
      expect(spec).not_to have_key(:swagger)

      # AC: Info object properly structured
      expect(spec[:info]).to be_a(Hash)
      expect(spec[:info][:title]).to eq('Test API')

      # AC: Paths object maintained
      expect(spec[:paths]).to be_a(Hash)

      # AC: Components object created
      # (Will be present if definitions are provided)

      # AC: Valid OpenAPI 3.1.0 document structure
      expect(spec.keys).to include(:openapi, :info, :paths)
    end
  end

  describe 'Story 2.2: Server Configuration' do
    it 'handles server configuration correctly' do
      # AC: Servers array replaces host/basePath/schemes
      legacy_options = {
        info: { title: 'API' },
        host: 'api.example.com',
        base_path: '/v1',
        schemes: ['https']
      }

      spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(legacy_options)
      expect(spec[:servers]).to be_an(Array)
      expect(spec).not_to have_key(:host)
      expect(spec).not_to have_key(:basePath)
      expect(spec).not_to have_key(:schemes)

      # AC: Support multiple server definitions
      multi_server_options = {
        info: { title: 'API' },
        servers: [
          { url: 'https://prod.example.com' },
          { url: 'https://staging.example.com' }
        ]
      }

      spec2 = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(multi_server_options)
      expect(spec2[:servers].size).to eq(2)

      # AC: Server variables supported
      var_options = {
        info: { title: 'API' },
        servers: [
          {
            url: 'https://{env}.example.com',
            variables: { env: { default: 'prod' } }
          }
        ]
      }

      spec3 = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(var_options)
      expect(spec3[:servers][0][:variables]).to be_a(Hash)

      # AC: Backward compatible conversion from host/basePath
      # (Already tested above)
    end
  end

  describe 'Story 2.3: Components Structure' do
    it 'organizes components correctly' do
      options = {
        info: { title: 'API' },
        definitions: { 'User' => { type: 'object' } },
        components: {
          parameters: { 'Page' => { name: 'page' } },
          responses: { 'NotFound' => { description: 'Not found' } }
        },
        securityDefinitions: {
          'api_key' => { type: 'apiKey', name: 'key', in: 'header' }
        }
      }

      spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(options)

      # AC: Components object with schemas sub-object
      expect(spec[:components]).to be_a(Hash)
      expect(spec[:components][:schemas]).to be_a(Hash)

      # AC: Definitions moved to components.schemas
      expect(spec[:components][:schemas]).to have_key('User')
      expect(spec).not_to have_key(:definitions)

      # AC: Parameters can be defined in components
      expect(spec[:components][:parameters]).to have_key('Page')

      # AC: Responses can be defined in components
      expect(spec[:components][:responses]).to have_key('NotFound')

      # AC: Security schemes in components
      expect(spec[:components][:securitySchemes]).to have_key('api_key')
      expect(spec).not_to have_key(:securityDefinitions)
    end
  end
end
