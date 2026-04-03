# frozen_string_literal: true

require 'grape'
require 'grape-swagger'
require 'grape-entity'
require 'grape-swagger-entity'

# Entity models for response serialization
module Demo
  module Entities
    class User < Grape::Entity
      expose :id, documentation: { type: Integer, desc: 'User ID' }
      expose :name, documentation: { type: String, desc: 'User name' }
      expose :email, documentation: { type: String, desc: 'User email address' }
      expose :role, documentation: { type: String, desc: 'User role', values: %w[admin member guest] }
    end
  end
end

class DemoAPI < Grape::API
  format :json

  # -- Health check (simple GET) --
  desc 'Health check'
  get :status do
    { status: 'ok' }
  end

  # -- Users resource: demonstrates POST with requestBody,
  #    GET with query/path params, and response entities --
  resource :users do
    desc 'List users',
         is_array: true,
         success: Demo::Entities::User
    params do
      optional :role, type: String, values: %w[admin member guest], desc: 'Filter by role'
      optional :page, type: Integer, desc: 'Page number'
      optional :per_page, type: Integer, desc: 'Items per page'
    end
    get do
      present [{ id: 1, name: 'Alice', email: 'alice@example.com', role: 'admin' }],
              with: Demo::Entities::User
    end

    desc 'Get a user by ID',
         success: Demo::Entities::User
    params do
      requires :id, type: Integer, desc: 'User ID'
    end
    get ':id' do
      present({ id: params[:id], name: 'Alice', email: 'alice@example.com', role: 'admin' },
              with: Demo::Entities::User)
    end

    desc 'Create a user',
         success: { code: 201, model: Demo::Entities::User, message: 'User created' }
    params do
      requires :name, type: String, desc: 'User name'
      requires :email, type: String, desc: 'User email address'
      optional :role, type: String, values: %w[admin member guest], desc: 'User role'
    end
    post do
      status 201
      present({ id: 1, name: params[:name], email: params[:email], role: params[:role] || 'member' },
              with: Demo::Entities::User)
    end

    desc 'Update a user',
         success: Demo::Entities::User
    params do
      requires :id, type: Integer, desc: 'User ID'
      optional :name, type: String, desc: 'User name'
      optional :email, type: String, desc: 'User email address'
    end
    put ':id' do
      present({ id: params[:id], name: params[:name], email: params[:email], role: 'admin' },
              with: Demo::Entities::User)
    end

    desc 'Delete a user'
    params do
      requires :id, type: Integer, desc: 'User ID'
    end
    delete ':id' do
      status 204
      nil
    end
  end

  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'Demo API',
      description: 'Showcase of OpenAPI 3.1.0 features implemented in grape-swagger',
      version: '1.0.0'
    },
    security_definitions: {
      api_key: {
        type: 'apiKey',
        name: 'X-API-Key',
        in: 'header',
        description: 'API key authentication'
      },
      oauth2: {
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
    },
    security: [{ api_key: [] }],
    webhooks: {
      user_created: {
        summary: 'User created event',
        description: 'Triggered when a new user is created',
        request: {
          description: 'User payload',
          schema: { '$ref' => '#/components/schemas/User' }
        },
        responses: {
          200 => { description: 'Webhook processed successfully' }
        }
      }
    }
  )
end
