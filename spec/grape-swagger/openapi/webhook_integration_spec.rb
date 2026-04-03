# frozen_string_literal: true

require 'spec_helper'

describe 'Webhook Integration' do
  describe 'SpecBuilderV3_1 with webhooks' do
    it 'includes processed webhooks in assembled spec' do
      options = {
        info: { title: 'Webhook API', version: '1.0.0' },
        webhooks: {
          user_created: {
            summary: 'User created event',
            description: 'Triggered when a new user is created',
            request: {
              description: 'User payload',
              schema: { '$ref' => '#/components/schemas/User' }
            },
            responses: {
              200 => { description: 'Webhook processed' },
              400 => { description: 'Invalid payload' }
            }
          }
        }
      }

      spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(options)

      expect(spec[:openapi]).to eq('3.1.0')
      expect(spec[:webhooks]).to be_a(Hash)
      expect(spec[:webhooks]).to have_key('user_created')

      webhook = spec[:webhooks]['user_created']
      expect(webhook).to have_key(:post)
      expect(webhook[:post][:summary]).to eq('User created event')
      expect(webhook[:post][:description]).to eq('Triggered when a new user is created')
      expect(webhook[:post][:requestBody][:content]['application/json'][:schema]).to eq(
        { '$ref' => '#/components/schemas/User' }
      )
      expect(webhook[:post][:responses]).to have_key('200')
      expect(webhook[:post][:responses]).to have_key('400')
    end

    it 'omits webhooks from spec when definitions are empty' do
      options = {
        info: { title: 'Webhook API' },
        webhooks: {}
      }

      spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(options)

      expect(spec).not_to have_key(:webhooks)
    end

    it 'assembles spec with multiple webhooks and other top-level fields' do
      options = {
        info: { title: 'Full API', version: '2.0.0' },
        paths: {
          '/users' => {
            get: { summary: 'List users', responses: { '200' => { description: 'OK' } } }
          }
        },
        webhooks: {
          user_signup: {
            summary: 'New user',
            request: {
              schema: {
                type: 'object',
                properties: {
                  id: { type: 'integer' },
                  email: { type: 'string' }
                }
              }
            },
            responses: { 200 => { description: 'OK' } }
          },
          order_placed: {
            summary: 'Order placed',
            method: :put,
            request: {
              schema: { '$ref' => '#/components/schemas/Order' }
            },
            responses: {
              200 => { description: 'Received' },
              500 => { description: 'Server error' }
            }
          }
        },
        tags: [{ name: 'users', description: 'User operations' }],
        security: [{ 'BearerAuth' => [] }]
      }

      spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(options)

      # Verify all top-level fields coexist
      expect(spec[:openapi]).to eq('3.1.0')
      expect(spec[:paths]).to have_key('/users')
      expect(spec[:tags]).to be_an(Array)
      expect(spec[:security]).to be_an(Array)
      expect(spec[:webhooks].keys).to contain_exactly('user_signup', 'order_placed')

      # Verify user_signup uses default POST
      expect(spec[:webhooks]['user_signup']).to have_key(:post)
      signup_schema = spec[:webhooks]['user_signup'][:post][:requestBody][:content]['application/json'][:schema]
      expect(signup_schema[:type]).to eq('object')
      expect(signup_schema[:properties]).to have_key(:id)

      # Verify order_placed uses PUT
      expect(spec[:webhooks]['order_placed']).to have_key(:put)
      expect(spec[:webhooks]['order_placed']).not_to have_key(:post)
    end

    it 'handles webhook with response schema content' do
      options = {
        info: { title: 'API' },
        webhooks: {
          payment_event: {
            request: { schema: { type: 'object' } },
            responses: {
              200 => {
                description: 'Acknowledged',
                schema: { '$ref' => '#/components/schemas/AckResponse' }
              }
            }
          }
        }
      }

      spec = GrapeSwagger::OpenAPI::SpecBuilderV3_1.build(options)

      response_200 = spec[:webhooks]['payment_event'][:post][:responses]['200']
      expect(response_200[:description]).to eq('Acknowledged')
      expect(response_200[:content]['application/json'][:schema]['$ref']).to eq('#/components/schemas/AckResponse')
    end
  end
end
