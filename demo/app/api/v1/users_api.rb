# frozen_string_literal: true

module V1
  class UsersAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :users do
      desc 'List all users',
           summary: 'Get a list of all users',
           detail: 'Returns all users with optional filtering by role and status.',
           is_array: true,
           success: {
             model: Entities::User,
             examples: {
               'application/json' => [
                 { id: 1, email: 'admin@example.com', name: 'Admin User', role: 'admin', is_active: true },
                 { id: 2, email: 'user@example.com', name: 'Regular User', role: 'user', is_active: true }
               ]
             }
           },
           failure: [
             { code: 401, message: 'Unauthorized', examples: { 'application/json' => { error: 'Invalid token' } } },
             { code: 403, message: 'Forbidden - Admin access required' }
           ],
           tags: ['users']
      params do
        optional :role, type: String, values: %w[admin moderator user guest], desc: 'Filter by user role'
        optional :active_only, type: Boolean, default: false, desc: 'Show only active users'
        optional :search, type: String, desc: 'Search by name or email'
        optional :limit, type: Integer, values: 1..100, default: 20, desc: 'Maximum number of results'
        optional :offset, type: Integer, values: 0..10_000, default: 0, desc: 'Pagination offset'
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
           summary: 'Retrieve authenticated user profile',
           detail: 'Returns the profile of the currently authenticated user.',
           success: {
             model: Entities::User,
             examples: {
               'application/json' => { id: 1, email: 'me@example.com', name: 'Current User', role: 'user',
                                       is_active: true }
             }
           },
           failure: [
             { code: 401, message: 'Unauthorized',
               examples: { 'application/json' => { error: 'Authentication required' } } }
           ],
           tags: ['users']
      get 'me' do
        user = {
          id: 1, email: 'me@example.com', name: 'Current User',
          role: 'user', is_active: true, created_at: Time.now
        }
        present user, with: Entities::User
      end

      desc 'Get user by ID',
           summary: 'Retrieve a specific user',
           detail: 'Returns detailed information about a user by their ID.',
           success: {
             model: Entities::User,
             examples: {
               'application/json' => { id: 1, email: 'user@example.com', name: 'Demo User', role: 'user',
                                       is_active: true }
             }
           },
           failure: [
             { code: 404, message: 'User not found',
               examples: { 'application/json' => { error: 'User with ID 999 not found' } } },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['users']
      params do
        requires :id, type: Integer, values: 1..2_147_483_647, desc: 'Unique user identifier'
      end
      get ':id' do
        user = { id: params[:id], email: 'user@example.com', name: 'Demo User', role: 'user' }
        present user, with: Entities::User
      end

      desc 'Create a new user',
           summary: 'Register a new user account',
           detail: 'Creates a new user account with the provided information.',
           success: {
             model: Entities::User,
             message: 'User created successfully',
             examples: {
               'application/json' => { id: 1234, email: 'new@example.com', name: 'New User', role: 'user',
                                       is_active: true }
             }
           },
           failure: [
             { code: 400, message: 'Validation error',
               examples: { 'application/json' => { error: 'Email format is invalid' } } },
             { code: 409, message: 'Email already exists',
               examples: { 'application/json' => { error: 'Email already registered' } } },
             { code: 422, message: 'Unprocessable Entity' }
           ],
           tags: ['users']
      params do
        requires :email, type: String, regexp: /.+@.+/, desc: 'Valid email address'
        requires :name, type: String, desc: 'Full name of the user'
        requires :password, type: String, desc: 'Password (minimum 8 characters)'
        optional :role, type: String, values: %w[admin moderator user guest], default: 'user', desc: 'User role'
        optional :avatar_url, type: String, desc: 'URL to user avatar image', allow_blank: true
        optional :bio, type: String, desc: 'Short biography', allow_blank: true
      end
      post do
        user = declared(params).merge(id: rand(1000..9999), is_active: true, created_at: Time.now)
        user.delete(:password)
        present user, with: Entities::User
      end

      desc 'Update user profile',
           summary: 'Modify user information',
           detail: 'Updates an existing user profile with the provided fields.',
           success: {
             model: Entities::User,
             examples: {
               'application/json' => { id: 1, email: 'user@example.com', name: 'Updated Name', role: 'user' }
             }
           },
           failure: [
             { code: 400, message: 'Validation error' },
             { code: 404, message: 'User not found' }
           ],
           tags: ['users']
      params do
        requires :id, type: Integer, values: 1..2_147_483_647, desc: 'Unique user identifier'
        optional :name, type: String, desc: 'New full name'
        optional :avatar_url, type: String, allow_blank: true, desc: 'New avatar URL'
        optional :bio, type: String, allow_blank: true, desc: 'New biography'
      end
      put ':id' do
        user = { id: params[:id], email: 'user@example.com', name: params[:name] || 'Demo User' }
        present user, with: Entities::User
      end

      desc 'Deactivate user account',
           summary: 'Soft delete a user',
           detail: 'Deactivates a user account. The account can be reactivated later.',
           failure: [
             { code: 404, message: 'User not found' },
             { code: 403, message: 'Cannot deactivate own account' }
           ],
           tags: ['users']
      params do
        requires :id, type: Integer, values: 1..2_147_483_647, desc: 'Unique user identifier'
      end
      delete ':id' do
        status 204
        body false
      end
    end
  end
end
