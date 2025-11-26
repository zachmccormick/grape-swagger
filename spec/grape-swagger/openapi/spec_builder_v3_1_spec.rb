# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::SpecBuilderV3_1 do
  describe '.build' do
    context 'root object structure' do
      it 'includes openapi field with version 3.1.0' do
        options = { info: { title: 'Test API' } }
        spec = described_class.build(options)
        expect(spec[:openapi]).to eq('3.1.0')
      end

      it 'does not include swagger field' do
        options = { info: { title: 'Test API' } }
        spec = described_class.build(options)
        expect(spec).not_to have_key(:swagger)
      end

      it 'includes info object' do
        options = { info: { title: 'Test API', version: '1.0.0' } }
        spec = described_class.build(options)
        expect(spec[:info]).to be_a(Hash)
        expect(spec[:info][:title]).to eq('Test API')
        expect(spec[:info][:version]).to eq('1.0.0')
      end

      it 'includes paths object' do
        options = {
          info: { title: 'Test API' },
          paths: {
            '/users' => {
              get: {
                summary: 'Get users',
                responses: {
                  '200' => { description: 'Success' }
                }
              }
            }
          }
        }
        spec = described_class.build(options)
        expect(spec[:paths]).to be_a(Hash)
        expect(spec[:paths]).to have_key('/users')
      end

      it 'includes components object when present' do
        options = {
          info: { title: 'Test API' },
          definitions: {
            'User' => { type: 'object' }
          }
        }
        spec = described_class.build(options)
        expect(spec[:components]).to be_a(Hash)
        expect(spec[:components][:schemas]).to have_key('User')
      end

      it 'includes servers array when present' do
        options = {
          info: { title: 'Test API' },
          host: 'api.example.com',
          schemes: ['https']
        }
        spec = described_class.build(options)
        expect(spec[:servers]).to be_an(Array)
        expect(spec[:servers].size).to be > 0
      end
    end

    context 'complete OpenAPI 3.1.0 document' do
      let(:complete_options) do
        {
          info: {
            title: 'Complete API',
            version: '2.0.0',
            description: 'A complete API specification'
          },
          servers: [
            { url: 'https://api.example.com', description: 'Production' }
          ],
          paths: {
            '/users' => {
              get: {
                summary: 'List users',
                responses: { '200' => { description: 'Success' } }
              }
            }
          },
          components: {
            schemas: {
              'User' => {
                type: 'object',
                properties: {
                  id: { type: 'integer' },
                  name: { type: 'string' }
                }
              }
            },
            securitySchemes: {
              'BearerAuth' => {
                type: 'http',
                scheme: 'bearer'
              }
            }
          },
          security: [
            { 'BearerAuth' => [] }
          ],
          tags: [
            { name: 'users', description: 'User operations' }
          ]
        }
      end

      it 'builds valid OpenAPI 3.1.0 document structure' do
        spec = described_class.build(complete_options)

        expect(spec[:openapi]).to eq('3.1.0')
        expect(spec[:info][:title]).to eq('Complete API')
        expect(spec[:servers]).to be_an(Array)
        expect(spec[:paths]).to have_key('/users')
        expect(spec[:components][:schemas]).to have_key('User')
        expect(spec[:components][:securitySchemes]).to have_key('BearerAuth')
        expect(spec[:security]).to be_an(Array)
        expect(spec[:tags]).to be_an(Array)
      end
    end

    context 'with minimal options' do
      it 'builds minimal valid spec' do
        options = { info: { title: 'Minimal API' } }
        spec = described_class.build(options)

        expect(spec[:openapi]).to eq('3.1.0')
        expect(spec[:info][:title]).to eq('Minimal API')
        expect(spec[:info][:version]).to eq('0.0.1')
      end
    end

    context 'backward compatibility' do
      it 'converts swagger 2.0 style options to OpenAPI 3.1.0' do
        options = {
          info: { title: 'Legacy API', version: '1.0.0' },
          host: 'api.example.com',
          base_path: '/v1',
          schemes: %w[https http],
          definitions: {
            'User' => { type: 'object' }
          },
          securityDefinitions: {
            'api_key' => { type: 'apiKey', name: 'api_key', in: 'header' }
          }
        }
        spec = described_class.build(options)

        # Should have OpenAPI 3.1.0 structure
        expect(spec[:openapi]).to eq('3.1.0')
        expect(spec).not_to have_key(:swagger)

        # Servers instead of host/basePath/schemes
        expect(spec[:servers]).to be_an(Array)
        expect(spec).not_to have_key(:host)
        expect(spec).not_to have_key(:basePath)
        expect(spec).not_to have_key(:schemes)

        # Components instead of definitions/securityDefinitions
        expect(spec[:components][:schemas]).to have_key('User')
        expect(spec[:components][:securitySchemes]).to have_key('api_key')
        expect(spec).not_to have_key(:definitions)
        expect(spec).not_to have_key(:securityDefinitions)
      end
    end

    context 'with tags' do
      it 'includes tags array' do
        options = {
          info: { title: 'Test API' },
          tags: [
            { name: 'users', description: 'User management' },
            { name: 'posts', description: 'Post management' }
          ]
        }
        spec = described_class.build(options)

        expect(spec[:tags]).to be_an(Array)
        expect(spec[:tags].size).to eq(2)
        expect(spec[:tags][0][:name]).to eq('users')
        expect(spec[:tags][1][:name]).to eq('posts')
      end
    end

    context 'with external docs' do
      it 'includes externalDocs' do
        options = {
          info: { title: 'Test API' },
          externalDocs: {
            description: 'Find more info here',
            url: 'https://example.com/docs'
          }
        }
        spec = described_class.build(options)

        expect(spec[:externalDocs]).to be_a(Hash)
        expect(spec[:externalDocs][:description]).to eq('Find more info here')
        expect(spec[:externalDocs][:url]).to eq('https://example.com/docs')
      end
    end

    context 'with security requirements' do
      it 'includes top-level security array' do
        options = {
          info: { title: 'Test API' },
          security: [
            { 'BearerAuth' => [] },
            { 'ApiKeyAuth' => [] }
          ]
        }
        spec = described_class.build(options)

        expect(spec[:security]).to be_an(Array)
        expect(spec[:security].size).to eq(2)
      end
    end

    context 'with webhooks (OpenAPI 3.1.0 feature)' do
      it 'includes webhooks object built from webhook definitions' do
        options = {
          info: { title: 'Test API' },
          webhooks: {
            user_signup: {
              summary: 'User signup event',
              description: 'Triggered when a new user registers',
              request: {
                schema: { '$ref' => '#/components/schemas/User' }
              },
              responses: {
                200 => { description: 'Webhook received' }
              }
            }
          }
        }
        spec = described_class.build(options)

        expect(spec[:webhooks]).to be_a(Hash)
        expect(spec[:webhooks]).to have_key('user_signup')
        expect(spec[:webhooks]['user_signup']).to have_key(:post)
        expect(spec[:webhooks]['user_signup'][:post][:summary]).to eq('User signup event')
      end

      it 'builds webhooks with requestBody and responses' do
        options = {
          info: { title: 'Test API' },
          webhooks: {
            order_created: {
              request: {
                description: 'Order details',
                schema: { type: 'object' }
              },
              responses: {
                200 => { description: 'Success' },
                400 => { description: 'Invalid payload' }
              }
            }
          }
        }
        spec = described_class.build(options)

        webhook = spec[:webhooks]['order_created'][:post]
        expect(webhook[:requestBody]).to have_key(:content)
        expect(webhook[:requestBody][:content]).to have_key('application/json')
        expect(webhook[:responses]).to have_key('200')
        expect(webhook[:responses]).to have_key('400')
      end

      it 'omits webhooks when not provided' do
        options = {
          info: { title: 'Test API' }
        }
        spec = described_class.build(options)

        expect(spec).not_to have_key(:webhooks)
      end

      it 'omits webhooks when empty' do
        options = {
          info: { title: 'Test API' },
          webhooks: {}
        }
        spec = described_class.build(options)

        expect(spec).not_to have_key(:webhooks)
      end

      it 'supports multiple webhooks' do
        options = {
          info: { title: 'Test API' },
          webhooks: {
            user_signup: {
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            },
            order_created: {
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            },
            payment_received: {
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            }
          }
        }
        spec = described_class.build(options)

        expect(spec[:webhooks].keys.size).to eq(3)
        expect(spec[:webhooks]).to have_key('user_signup')
        expect(spec[:webhooks]).to have_key('order_created')
        expect(spec[:webhooks]).to have_key('payment_received')
      end
    end

    context 'when info is missing' do
      it 'raises an error' do
        options = {}
        expect { described_class.build(options) }.to raise_error(ArgumentError, /info is required/)
      end
    end

    context 'empty paths handling' do
      it 'includes empty paths object when not provided' do
        options = { info: { title: 'Test API' } }
        spec = described_class.build(options)
        expect(spec[:paths]).to eq({})
      end
    end
  end
end
