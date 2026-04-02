# frozen_string_literal: true

require 'spec_helper'

describe 'Callbacks & Links Integration' do
  describe 'OpenAPI 3.1.0 with callbacks and links' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create subscription',
             callbacks: {
               onEvent: {
                 url: '{$request.body#/callbackUrl}',
                 method: :post,
                 summary: 'Event notification',
                 description: 'Triggered when an event occurs',
                 request: {
                   schema: { '$ref' => '#/components/schemas/Event' }
                 },
                 responses: {
                   200 => { description: 'Processed' },
                   400 => { description: 'Bad Request' }
                 }
               }
             }
        params do
          requires :callbackUrl, type: String
        end
        post '/subscriptions' do
          { id: 1 }
        end

        desc 'Create user',
             links: {
               201 => {
                 GetUserById: {
                   operation_id: 'getUser',
                   description: 'Retrieve the created user',
                   parameters: {
                     userId: '$response.body#/id'
                   }
                 },
                 GetUserPosts: {
                   operation_id: 'getUserPosts',
                   parameters: {
                     userId: '$response.body#/id'
                   }
                 }
               }
             },
             http_codes: [
               { code: 201, message: 'User created' }
             ]
        params do
          requires :name, type: String
        end
        post '/users' do
          { id: 1, name: params[:name] }
        end

        desc 'Create order with callbacks and links',
             callbacks: {
               onShipped: {
                 url: '{$request.body#/shippingWebhook}',
                 summary: 'Shipping notification',
                 request: {
                   schema: {
                     type: 'object',
                     properties: {
                       trackingNumber: { type: 'string' },
                       carrier: { type: 'string' }
                     }
                   }
                 },
                 responses: {
                   200 => { description: 'Acknowledged' }
                 }
               }
             },
             links: {
               201 => {
                 GetOrderById: {
                   operation_id: 'getOrder',
                   parameters: {
                     orderId: '$response.body#/id'
                   }
                 }
               }
             },
             http_codes: [
               { code: 201, message: 'Order created' }
             ]
        params do
          requires :item, type: String
          requires :shippingWebhook, type: String
        end
        post '/orders' do
          { id: 1 }
        end

        desc 'Get user by ID'
        params do
          requires :id, type: Integer
        end
        get '/users/:id' do
          { id: params[:id] }
        end

        add_swagger_documentation(
          openapi_version: '3.1.0'
        )
      end
    end

    subject do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)
    end

    let(:paths) { subject['paths'] }

    describe 'callbacks on operation' do
      let(:subscription_op) { paths['/subscriptions']['post'] }

      it 'includes callbacks in the operation' do
        expect(subscription_op).to have_key('callbacks')
      end

      it 'includes the callback name as key' do
        expect(subscription_op['callbacks']).to have_key('onEvent')
      end

      it 'uses runtime expression as URL key' do
        callback = subscription_op['callbacks']['onEvent']
        expect(callback).to have_key('{$request.body#/callbackUrl}')
      end

      it 'includes the HTTP method under the URL' do
        callback_path = subscription_op['callbacks']['onEvent']['{$request.body#/callbackUrl}']
        expect(callback_path).to have_key('post')
      end

      it 'includes summary and description' do
        operation = subscription_op['callbacks']['onEvent']['{$request.body#/callbackUrl}']['post']
        expect(operation['summary']).to eq('Event notification')
        expect(operation['description']).to eq('Triggered when an event occurs')
      end

      it 'includes requestBody with schema ref' do
        operation = subscription_op['callbacks']['onEvent']['{$request.body#/callbackUrl}']['post']
        expect(operation['requestBody']).to be_a(Hash)
        schema = operation['requestBody']['content']['application/json']['schema']
        expect(schema['$ref']).to eq('#/components/schemas/Event')
      end

      it 'includes response codes' do
        operation = subscription_op['callbacks']['onEvent']['{$request.body#/callbackUrl}']['post']
        expect(operation['responses']).to have_key('200')
        expect(operation['responses']).to have_key('400')
      end
    end

    describe 'links on response' do
      let(:user_op) { paths['/users']['post'] }

      it 'includes links in the 201 response' do
        response_201 = user_op['responses']['201']
        expect(response_201).to have_key('links')
      end

      it 'includes link names as keys' do
        links = user_op['responses']['201']['links']
        expect(links).to have_key('GetUserById')
        expect(links).to have_key('GetUserPosts')
      end

      it 'includes operationId in link' do
        link = user_op['responses']['201']['links']['GetUserById']
        expect(link['operationId']).to eq('getUser')
      end

      it 'includes parameter mapping with runtime expression' do
        link = user_op['responses']['201']['links']['GetUserById']
        expect(link['parameters']['userId']).to eq('$response.body#/id')
      end

      it 'includes link description' do
        link = user_op['responses']['201']['links']['GetUserById']
        expect(link['description']).to eq('Retrieve the created user')
      end
    end

    describe 'operation with both callbacks and links' do
      let(:order_op) { paths['/orders']['post'] }

      it 'includes callbacks' do
        expect(order_op).to have_key('callbacks')
        expect(order_op['callbacks']).to have_key('onShipped')
      end

      it 'includes links on response' do
        response_201 = order_op['responses']['201']
        expect(response_201).to have_key('links')
        expect(response_201['links']).to have_key('GetOrderById')
      end

      it 'callback has inline schema' do
        operation = order_op['callbacks']['onShipped']['{$request.body#/shippingWebhook}']['post']
        schema = operation['requestBody']['content']['application/json']['schema']
        expect(schema['type']).to eq('object')
        expect(schema['properties']).to have_key('trackingNumber')
        expect(schema['properties']).to have_key('carrier')
      end
    end

    describe 'operation without callbacks or links' do
      let(:get_user_op) { paths['/users/{id}']['get'] }

      it 'does not include callbacks key' do
        expect(get_user_op).not_to have_key('callbacks')
      end

      it 'does not include links on responses' do
        get_user_op['responses'].each_value do |response|
          expect(response).not_to have_key('links')
        end
      end
    end
  end

  describe 'Swagger 2.0 compatibility' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Create subscription',
             callbacks: {
               onEvent: {
                 url: '{$request.body#/callbackUrl}',
                 request: { schema: { type: 'object' } },
                 responses: { 200 => { description: 'OK' } }
               }
             },
             links: {
               200 => {
                 GetResource: {
                   operation_id: 'getResource',
                   parameters: { id: '$response.body#/id' }
                 }
               }
             }
        post '/subscriptions' do
          { id: 1 }
        end

        add_swagger_documentation
      end
    end

    subject do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)
    end

    it 'uses Swagger 2.0 format' do
      expect(subject['swagger']).to eq('2.0')
    end

    it 'does not include callbacks in operation' do
      operation = subject['paths']['/subscriptions']['post']
      expect(operation).not_to have_key('callbacks')
    end

    it 'does not include links in responses' do
      operation = subject['paths']['/subscriptions']['post']
      operation['responses'].each_value do |response|
        expect(response).not_to have_key('links')
      end
    end
  end
end
