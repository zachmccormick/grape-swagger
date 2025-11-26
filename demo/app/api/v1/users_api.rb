# frozen_string_literal: true

module V1
  class UsersAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :users do
      desc 'List all users',
           is_array: true,
           success: { model: Entities::User },
           failure: [
             { code: 401, message: 'Unauthorized' },
             { code: 403, message: 'Forbidden - Admin access required' }
           ],
           tags: ['users']
      params do
        optional :role, type: String, values: %w[admin moderator user guest]
        optional :active_only, type: Boolean, default: false
        optional :search, type: String, desc: 'Search by name or email'
      end
      get do
        users = [
          {
            id: 1, email: 'admin@example.com', name: 'Admin User',
            role: 'admin', is_active: true, avatar_url: nil
          },
          {
            id: 2, email: 'user@example.com', name: 'Regular User',
            role: 'user', is_active: true, bio: 'Hello world!'
          }
        ]
        present users, with: Entities::User
      end

      desc 'Get current user profile',
           success: { model: Entities::User },
           failure: [{ code: 401, message: 'Unauthorized' }],
           tags: ['users']
      get 'me' do
        user = {
          id: 1, email: 'me@example.com', name: 'Current User',
          role: 'user', is_active: true, created_at: Time.now
        }
        present user, with: Entities::User
      end

      desc 'Get user by ID',
           success: { model: Entities::User },
           failure: [
             { code: 404, message: 'User not found' },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['users']
      params do
        requires :id, type: Integer, desc: 'User ID'
      end
      get ':id' do
        user = { id: params[:id], email: 'user@example.com', name: 'Demo User', role: 'user' }
        present user, with: Entities::User
      end

      desc 'Create a new user',
           success: { model: Entities::User, message: 'User created successfully' },
           failure: [
             { code: 400, message: 'Validation error' },
             { code: 409, message: 'Email already exists' },
             { code: 422, message: 'Unprocessable Entity' }
           ],
           tags: ['users']
      params do
        requires :email, type: String, regexp: /.+@.+/, desc: 'Email address'
        requires :name, type: String, desc: 'Full name'
        requires :password, type: String, desc: 'Password (min 8 chars)'
        optional :role, type: String, values: %w[admin moderator user guest], default: 'user'
        optional :avatar_url, type: String, desc: 'Avatar URL (nullable)', allow_blank: true
        optional :bio, type: String, desc: 'User biography (nullable)', allow_blank: true
      end
      post do
        user = declared(params).merge(id: rand(1000..9999), is_active: true, created_at: Time.now)
        user.delete(:password)
        present user, with: Entities::User
      end

      desc 'Update user profile',
           success: { model: Entities::User },
           failure: [
             { code: 400, message: 'Validation error' },
             { code: 404, message: 'User not found' }
           ],
           tags: ['users']
      params do
        requires :id, type: Integer, desc: 'User ID'
        optional :name, type: String
        optional :avatar_url, type: String, allow_blank: true
        optional :bio, type: String, allow_blank: true
      end
      put ':id' do
        user = { id: params[:id], email: 'user@example.com', name: params[:name] || 'Demo User' }
        present user, with: Entities::User
      end

      desc 'Deactivate user account',
           failure: [
             { code: 404, message: 'User not found' },
             { code: 403, message: 'Cannot deactivate own account' }
           ],
           tags: ['users']
      params do
        requires :id, type: Integer, desc: 'User ID'
      end
      delete ':id' do
        status 204
        body false
      end
    end
  end
end
