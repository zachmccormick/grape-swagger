# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::WebhookBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }

  describe '.build' do
    # Story 11.1: Webhook Definition Structure
    context 'Story 11.1: Webhook Definition Structure' do
      context 'when webhook definitions are provided' do
        it 'creates top-level webhooks object' do
          webhook_definitions = {
            user_signup: {
              summary: 'User signup event',
              description: 'Triggered when a new user registers',
              request: {
                description: 'User data payload',
                schema: { '$ref' => '#/components/schemas/User' }
              },
              responses: {
                200 => { description: 'Webhook received' }
              }
            }
          }

          result = described_class.build(webhook_definitions, version_3_1_0)

          expect(result).not_to be_nil
          expect(result).to be_a(Hash)
          expect(result).to have_key('user_signup')
        end

        it 'uses webhook names as keys' do
          webhook_definitions = {
            user_signup: {},
            order_created: {}
          }

          result = described_class.build(webhook_definitions, version_3_1_0)

          expect(result.keys).to include('user_signup', 'order_created')
        end

        it 'creates POST operation by default for webhooks' do
          webhook_definitions = {
            user_signup: {
              summary: 'User signup',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'Success' } }
            }
          }

          result = described_class.build(webhook_definitions, version_3_1_0)

          expect(result['user_signup']).to have_key(:post)
        end

        it 'includes summary in webhook operation' do
          webhook_definitions = {
            user_signup: {
              summary: 'User signup event',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'Success' } }
            }
          }

          result = described_class.build(webhook_definitions, version_3_1_0)

          expect(result['user_signup'][:post][:summary]).to eq('User signup event')
        end

        it 'includes description in webhook operation' do
          webhook_definitions = {
            user_signup: {
              summary: 'User signup',
              description: 'Triggered when a new user registers',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'Success' } }
            }
          }

          result = described_class.build(webhook_definitions, version_3_1_0)

          expect(result['user_signup'][:post][:description]).to eq('Triggered when a new user registers')
        end

        it 'creates requestBody with content types' do
          webhook_definitions = {
            user_signup: {
              request: {
                description: 'User data',
                schema: { type: 'object' }
              },
              responses: { 200 => { description: 'Success' } }
            }
          }

          result = described_class.build(webhook_definitions, version_3_1_0)

          expect(result['user_signup'][:post]).to have_key(:requestBody)
          expect(result['user_signup'][:post][:requestBody]).to have_key(:content)
          expect(result['user_signup'][:post][:requestBody][:content]).to have_key('application/json')
        end

        it 'includes response codes and schemas' do
          webhook_definitions = {
            user_signup: {
              request: { schema: { type: 'object' } },
              responses: {
                200 => { description: 'Success' },
                400 => { description: 'Invalid payload' }
              }
            }
          }

          result = described_class.build(webhook_definitions, version_3_1_0)

          expect(result['user_signup'][:post]).to have_key(:responses)
          expect(result['user_signup'][:post][:responses]).to have_key('200')
          expect(result['user_signup'][:post][:responses]).to have_key('400')
        end

        it 'does not include parameters array (webhooks do not have params)' do
          webhook_definitions = {
            user_signup: {
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'Success' } }
            }
          }

          result = described_class.build(webhook_definitions, version_3_1_0)

          expect(result['user_signup'][:post]).not_to have_key(:parameters)
        end
      end

      context 'when webhook definitions are empty' do
        it 'returns nil for empty hash' do
          result = described_class.build({}, version_3_1_0)

          expect(result).to be_nil
        end

        it 'returns nil for nil' do
          result = described_class.build(nil, version_3_1_0)

          expect(result).to be_nil
        end
      end
    end

    # Story 11.2: Webhook Configuration API
    context 'Story 11.2: Webhook Configuration API' do
      it 'supports multiple webhooks' do
        webhook_definitions = {
          user_signup: {
            summary: 'User signup',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'Success' } }
          },
          order_created: {
            summary: 'Order created',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'Success' } }
          },
          payment_received: {
            summary: 'Payment received',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'Success' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        expect(result.keys.size).to eq(3)
        expect(result.keys).to include('user_signup', 'order_created', 'payment_received')
      end

      it 'includes example payloads in requestBody' do
        webhook_definitions = {
          user_signup: {
            request: {
              schema: { type: 'object' },
              examples: {
                default: {
                  value: { id: 1, email: 'user@example.com' }
                }
              }
            },
            responses: { 200 => { description: 'Success' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        expect(result['user_signup'][:post][:requestBody][:content]['application/json']).to have_key(:examples)
      end

      it 'supports operation-specific method (not just POST)' do
        webhook_definitions = {
          user_signup: {
            method: :get,
            summary: 'User signup verification',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'Success' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        expect(result['user_signup']).to have_key(:get)
        expect(result['user_signup']).not_to have_key(:post)
      end
    end

    # Story 11.3: Webhook Schema References
    context 'Story 11.3: Webhook Schema References' do
      it 'supports $ref to components/schemas' do
        webhook_definitions = {
          user_signup: {
            request: {
              schema: { '$ref' => '#/components/schemas/User' }
            },
            responses: { 200 => { description: 'Success' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        schema = result['user_signup'][:post][:requestBody][:content]['application/json'][:schema]
        expect(schema).to have_key('$ref')
        expect(schema['$ref']).to eq('#/components/schemas/User')
      end

      it 'supports inline schema definitions' do
        webhook_definitions = {
          user_signup: {
            request: {
              schema: {
                type: 'object',
                properties: {
                  id: { type: 'integer' },
                  email: { type: 'string' }
                }
              }
            },
            responses: { 200 => { description: 'Success' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        schema = result['user_signup'][:post][:requestBody][:content]['application/json'][:schema]
        expect(schema[:type]).to eq('object')
        expect(schema[:properties]).to have_key(:id)
        expect(schema[:properties]).to have_key(:email)
      end

      it 'supports array schemas for batch events' do
        webhook_definitions = {
          batch_events: {
            request: {
              schema: {
                type: 'array',
                items: { '$ref' => '#/components/schemas/Event' }
              }
            },
            responses: { 200 => { description: 'Success' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        schema = result['batch_events'][:post][:requestBody][:content]['application/json'][:schema]
        expect(schema[:type]).to eq('array')
        expect(schema[:items]).to have_key('$ref')
      end

      it 'supports response schemas with $ref' do
        webhook_definitions = {
          user_signup: {
            request: { schema: { type: 'object' } },
            responses: {
              200 => {
                description: 'Success',
                schema: { '$ref' => '#/components/schemas/WebhookResponse' }
              }
            }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        response = result['user_signup'][:post][:responses]['200']
        expect(response).to have_key(:content)
        expect(response[:content]['application/json'][:schema]).to have_key('$ref')
      end
    end

    # Additional edge cases
    context 'edge cases' do
      it 'handles webhooks with only required fields' do
        webhook_definitions = {
          minimal_webhook: {
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        expect(result).not_to be_nil
        expect(result['minimal_webhook'][:post]).to have_key(:requestBody)
        expect(result['minimal_webhook'][:post]).to have_key(:responses)
      end

      it 'sets requestBody required to true by default' do
        webhook_definitions = {
          user_signup: {
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'Success' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        expect(result['user_signup'][:post][:requestBody][:required]).to be true
      end

      it 'allows requestBody required to be overridden' do
        webhook_definitions = {
          user_signup: {
            request: {
              schema: { type: 'object' },
              required: false
            },
            responses: { 200 => { description: 'Success' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        expect(result['user_signup'][:post][:requestBody][:required]).to be false
      end
    end

    context 'custom content types' do
      it 'uses content_type from request config' do
        webhook_definitions = {
          file_upload: {
            summary: 'File uploaded',
            request: {
              content_type: 'application/xml',
              schema: { '$ref' => '#/components/schemas/FileEvent' }
            },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        content = result['file_upload'][:post][:requestBody][:content]
        expect(content).to have_key('application/xml')
        expect(content).not_to have_key('application/json')
      end

      it 'uses content_type from response config' do
        webhook_definitions = {
          event: {
            request: { schema: { type: 'object' } },
            responses: {
              200 => {
                description: 'OK',
                content_type: 'text/plain',
                schema: { type: 'string' }
              }
            }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        response_content = result['event'][:post][:responses]['200'][:content]
        expect(response_content).to have_key('text/plain')
        expect(response_content).not_to have_key('application/json')
      end

      it 'defaults to application/json when no content_type specified' do
        webhook_definitions = {
          event: {
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(webhook_definitions, version_3_1_0)

        content = result['event'][:post][:requestBody][:content]
        expect(content).to have_key('application/json')
      end
    end
  end
end
