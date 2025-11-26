# frozen_string_literal: true

require 'spec_helper'

describe 'Links Integration' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Create a user',
           success: { code: 201, message: 'User created' },
           failure: [[400, 'Bad Request']],
           links: {
             201 => {
               GetUserById: {
                 operation_id: 'getUser',
                 parameters: {
                   userId: '$response.body#/id'
                 },
                 description: 'Retrieve the created user'
               }
             }
           }
      post '/users' do
        { id: 123, name: 'John Doe' }
      end

      desc 'Get a user by ID',
           operationId: 'getUser'
      params do
        requires :id, type: Integer, desc: 'User ID'
      end
      get '/users/:id' do
        { id: params[:id], name: 'John Doe' }
      end

      add_swagger_documentation(openapi_version: '3.1.0')
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it 'includes links in response' do
    expect(subject['paths']['/users']['post']['responses']['201']).to have_key('links')
  end

  it 'creates link with operationId' do
    links = subject['paths']['/users']['post']['responses']['201']['links']
    expect(links).to have_key('GetUserById')
    expect(links['GetUserById']['operationId']).to eq('getUser')
  end

  it 'includes link parameter mapping' do
    link = subject['paths']['/users']['post']['responses']['201']['links']['GetUserById']
    expect(link['parameters']).to have_key('userId')
    expect(link['parameters']['userId']).to eq('$response.body#/id')
  end

  it 'includes link description' do
    link = subject['paths']['/users']['post']['responses']['201']['links']['GetUserById']
    expect(link['description']).to eq('Retrieve the created user')
  end
end
