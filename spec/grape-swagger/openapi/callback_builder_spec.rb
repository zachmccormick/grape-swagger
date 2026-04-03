# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::CallbackBuilder do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe '.build' do
    # Story 12.1: Callback Implementation
    context 'Story 12.1: Callback Implementation' do
      context 'when callback definitions are provided' do
        it 'creates callbacks object in operation' do
          callbacks = {
            onEvent: {
              url: '{$request.body#/callbackUrl}',
              method: :post,
              summary: 'Event notification',
              request: {
                schema: { '$ref' => '#/components/schemas/Event' }
              },
              responses: {
                200 => { description: 'Processed' }
              }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          expect(result).not_to be_nil
          expect(result).to be_a(Hash)
          expect(result).to have_key('onEvent')
        end

        it 'uses callback names as keys' do
          callbacks = {
            onEvent: {
              url: '{$request.body#/callbackUrl}',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            },
            onError: {
              url: '{$request.body#/errorUrl}',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          expect(result.keys).to include('onEvent', 'onError')
        end

        it 'creates POST operation by default' do
          callbacks = {
            onEvent: {
              url: '{$request.body#/callbackUrl}',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          callback_path = result['onEvent']['{$request.body#/callbackUrl}']
          expect(callback_path).to have_key(:post)
        end

        it 'supports PUT method for callbacks' do
          callbacks = {
            onUpdate: {
              url: '{$request.body#/callbackUrl}',
              method: :put,
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          callback_path = result['onUpdate']['{$request.body#/callbackUrl}']
          expect(callback_path).to have_key(:put)
          expect(callback_path).not_to have_key(:post)
        end

        it 'supports DELETE method for callbacks' do
          callbacks = {
            onDelete: {
              url: '{$request.body#/callbackUrl}',
              method: :delete,
              request: { schema: { type: 'object' } },
              responses: { 204 => { description: 'Deleted' } }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          callback_path = result['onDelete']['{$request.body#/callbackUrl}']
          expect(callback_path).to have_key(:delete)
        end

        it 'includes requestBody schema' do
          callbacks = {
            onEvent: {
              url: '{$request.body#/callbackUrl}',
              request: {
                schema: { '$ref' => '#/components/schemas/Event' }
              },
              responses: { 200 => { description: 'OK' } }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          callback_path = result['onEvent']['{$request.body#/callbackUrl}']
          expect(callback_path[:post]).to have_key(:requestBody)
          expect(callback_path[:post][:requestBody][:content]['application/json'][:schema]).to have_key('$ref')
        end

        it 'includes response codes' do
          callbacks = {
            onEvent: {
              url: '{$request.body#/callbackUrl}',
              request: { schema: { type: 'object' } },
              responses: {
                200 => { description: 'Success' },
                400 => { description: 'Bad Request' }
              }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          callback_path = result['onEvent']['{$request.body#/callbackUrl}']
          expect(callback_path[:post][:responses]).to have_key('200')
          expect(callback_path[:post][:responses]).to have_key('400')
        end

        it 'supports multiple callbacks per operation' do
          callbacks = {
            onEvent: {
              url: '{$request.body#/callbackUrl}',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            },
            onError: {
              url: '{$request.body#/errorUrl}',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            },
            onComplete: {
              url: '{$request.body#/completeUrl}',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          expect(result.keys.size).to eq(3)
          expect(result.keys).to include('onEvent', 'onError', 'onComplete')
        end

        it 'includes callback summary' do
          callbacks = {
            onEvent: {
              url: '{$request.body#/callbackUrl}',
              summary: 'Event notification callback',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          callback_path = result['onEvent']['{$request.body#/callbackUrl}']
          expect(callback_path[:post][:summary]).to eq('Event notification callback')
        end

        it 'includes callback description' do
          callbacks = {
            onEvent: {
              url: '{$request.body#/callbackUrl}',
              description: 'This callback is triggered when an event occurs',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            }
          }

          result = described_class.build(callbacks, version_3_1_0)

          callback_path = result['onEvent']['{$request.body#/callbackUrl}']
          expect(callback_path[:post][:description]).to eq('This callback is triggered when an event occurs')
        end
      end

      context 'when Swagger 2.0 is used' do
        it 'returns nil (callbacks not supported in Swagger 2.0)' do
          callbacks = {
            onEvent: {
              url: '{$request.body#/callbackUrl}',
              request: { schema: { type: 'object' } },
              responses: { 200 => { description: 'OK' } }
            }
          }

          result = described_class.build(callbacks, version_2_0)

          expect(result).to be_nil
        end
      end

      context 'when callbacks are empty' do
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

    # Story 12.2: Runtime Expressions
    context 'Story 12.2: Runtime Expressions' do
      it 'supports $url expression' do
        callbacks = {
          onEvent: {
            url: '{$url}',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        expect(result['onEvent']).to have_key('{$url}')
      end

      it 'supports $method expression' do
        callbacks = {
          onEvent: {
            url: 'https://example.com/callback?method={$method}',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        url_key = 'https://example.com/callback?method={$method}'
        expect(result['onEvent']).to have_key(url_key)
      end

      it 'supports $request.body#/pointer expression' do
        callbacks = {
          onEvent: {
            url: '{$request.body#/callbackUrl}',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        expect(result['onEvent']).to have_key('{$request.body#/callbackUrl}')
      end

      it 'supports $request.query.param expression' do
        callbacks = {
          onEvent: {
            url: 'https://example.com/callback?id={$request.query.userId}',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        url_key = 'https://example.com/callback?id={$request.query.userId}'
        expect(result['onEvent']).to have_key(url_key)
      end

      it 'supports $request.header.X-Header expression' do
        callbacks = {
          onEvent: {
            url: 'https://example.com/callback?auth={$request.header.Authorization}',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        url_key = 'https://example.com/callback?auth={$request.header.Authorization}'
        expect(result['onEvent']).to have_key(url_key)
      end

      it 'supports $response.body#/pointer expression' do
        callbacks = {
          onEvent: {
            url: '{$response.body#/webhookUrl}',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        expect(result['onEvent']).to have_key('{$response.body#/webhookUrl}')
      end

      it 'supports multiple runtime expressions in URL' do
        callbacks = {
          onEvent: {
            url: '{$request.body#/baseUrl}/callback?id={$request.body#/id}&method={$method}',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        url_key = '{$request.body#/baseUrl}/callback?id={$request.body#/id}&method={$method}'
        expect(result['onEvent']).to have_key(url_key)
      end
    end

    # Edge cases
    context 'edge cases' do
      it 'handles callbacks with only required fields' do
        callbacks = {
          minimal: {
            url: '{$request.body#/url}',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        expect(result).not_to be_nil
        callback_path = result['minimal']['{$request.body#/url}']
        expect(callback_path[:post]).to have_key(:requestBody)
        expect(callback_path[:post]).to have_key(:responses)
      end

      it 'sets requestBody required to true by default' do
        callbacks = {
          onEvent: {
            url: '{$request.body#/url}',
            request: { schema: { type: 'object' } },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        callback_path = result['onEvent']['{$request.body#/url}']
        expect(callback_path[:post][:requestBody][:required]).to be true
      end

      it 'allows requestBody required to be overridden' do
        callbacks = {
          onEvent: {
            url: '{$request.body#/url}',
            request: {
              schema: { type: 'object' },
              required: false
            },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        callback_path = result['onEvent']['{$request.body#/url}']
        expect(callback_path[:post][:requestBody][:required]).to be false
      end

      it 'supports inline schema definitions' do
        callbacks = {
          onEvent: {
            url: '{$request.body#/url}',
            request: {
              schema: {
                type: 'object',
                properties: {
                  eventType: { type: 'string' },
                  timestamp: { type: 'string', format: 'date-time' }
                }
              }
            },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)

        callback_path = result['onEvent']['{$request.body#/url}']
        schema = callback_path[:post][:requestBody][:content]['application/json'][:schema]
        expect(schema[:type]).to eq('object')
        expect(schema[:properties]).to have_key(:eventType)
        expect(schema[:properties]).to have_key(:timestamp)
      end
    end

    context 'custom content types' do
      it 'uses content_type from request config' do
        callbacks = {
          onEvent: {
            url: '{$request.body#/callbackUrl}',
            request: {
              content_type: 'application/xml',
              schema: { '$ref' => '#/components/schemas/Event' }
            },
            responses: { 200 => { description: 'OK' } }
          }
        }

        result = described_class.build(callbacks, version_3_1_0)
        content = result['onEvent'].values.first[:post][:requestBody][:content]
        expect(content).to have_key('application/xml')
        expect(content).not_to have_key('application/json')
      end

      it 'uses content_type from response config' do
        callbacks = {
          onEvent: {
            url: '{$request.body#/callbackUrl}',
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

        result = described_class.build(callbacks, version_3_1_0)
        response = result['onEvent'].values.first[:post][:responses]['200']
        expect(response[:content]).to have_key('text/plain')
        expect(response[:content]).not_to have_key('application/json')
      end
    end
  end
end
