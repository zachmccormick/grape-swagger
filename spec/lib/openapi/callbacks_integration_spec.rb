# frozen_string_literal: true

require 'spec_helper'

describe 'Callbacks Integration' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Subscribe to events',
           callbacks: {
             onEvent: {
               url: '{$request.body#/callbackUrl}',
               method: :post,
               summary: 'Event notification',
               request: {
                 schema: { type: 'object', properties: { eventType: { type: 'string' } } }
               },
               responses: {
                 200 => { description: 'Callback processed' }
               }
             }
           }
      params do
        requires :callbackUrl, type: String, desc: 'URL for event callbacks'
      end
      post '/subscribe' do
        { status: 'subscribed' }
      end

      add_swagger_documentation(openapi_version: '3.1.0')
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it 'includes callbacks in operation' do
    expect(subject['paths']['/subscribe']['post']).to have_key('callbacks')
  end

  it 'creates callback with runtime expression URL' do
    callbacks = subject['paths']['/subscribe']['post']['callbacks']
    expect(callbacks).to have_key('onEvent')
    expect(callbacks['onEvent']).to have_key('{$request.body#/callbackUrl}')
  end

  it 'includes callback operation details' do
    callback_op = subject['paths']['/subscribe']['post']['callbacks']['onEvent']['{$request.body#/callbackUrl}']['post']
    expect(callback_op['summary']).to eq('Event notification')
    expect(callback_op).to have_key('requestBody')
    expect(callback_op).to have_key('responses')
  end
end
