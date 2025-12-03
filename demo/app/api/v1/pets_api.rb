# frozen_string_literal: true

module V1
  class PetsAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :pets do
      desc 'List all pets',
           summary: 'Get a paginated list of pets',
           detail: 'Returns a list of all pets with optional filtering by type.',
           is_array: true,
           success: {
             model: Entities::Pet,
             message: 'List of pets',
             examples: {
               'application/json' => [
                 { id: 1, name: 'Buddy', pet_type: 'dog', breed: 'Golden Retriever' },
                 { id: 2, name: 'Whiskers', pet_type: 'cat', color: 'orange' }
               ]
             }
           },
           failure: [
             { code: 401, message: 'Unauthorized', examples: { 'application/json' => { error: 'Invalid token' } } },
             { code: 500, message: 'Internal Server Error' }
           ],
           tags: ['pets']
      params do
        optional :type, type: String, values: %w[dog cat bird], desc: 'Filter by pet type'
        optional :limit, type: Integer, values: 1..100, default: 20, desc: 'Number of results to return'
        optional :offset, type: Integer, values: 0..10_000, default: 0, desc: 'Offset for pagination'
      end
      get do
        # Demo data
        pets = [
          { id: 1, name: 'Buddy', pet_type: 'dog', breed: 'Golden Retriever', is_trained: true },
          { id: 2, name: 'Whiskers', pet_type: 'cat', color: 'orange', is_indoor: true },
          { id: 3, name: 'Tweety', pet_type: 'bird', species: 'Canary', can_fly: true }
        ]

        pets = pets.select { |p| p[:pet_type] == params[:type] } if params[:type]

        present pets, with: Entities::Pet
      end

      desc 'Get a pet by ID',
           summary: 'Retrieve a specific pet',
           detail: 'Returns detailed information about a pet including type-specific fields.',
           success: {
             model: Entities::Pet,
             examples: {
               'application/json' => { id: 1, name: 'Buddy', pet_type: 'dog', breed: 'Golden Retriever',
                                       is_trained: true }
             }
           },
           failure: [
             { code: 404, message: 'Pet not found',
               examples: { 'application/json' => { error: 'Pet with ID 999 not found' } } },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['pets']
      params do
        requires :id, type: Integer, values: 1..2_147_483_647, desc: 'Unique pet identifier'
      end
      get ':id' do
        pet = { id: params[:id], name: 'Buddy', pet_type: 'dog', breed: 'Golden Retriever' }
        present pet, with: Entities::Dog
      end

      desc 'Create a new pet',
           summary: 'Register a new pet',
           detail: 'Creates a new pet record. Provide type-specific fields based on pet_type.',
           success: {
             model: Entities::Pet,
             message: 'Pet created',
             examples: {
               'application/json' => { id: 1234, name: 'Max', pet_type: 'dog', breed: 'Labrador',
                                       created_at: '2024-01-15T10:30:00Z' }
             }
           },
           failure: [
             { code: 400, message: 'Validation error',
               examples: { 'application/json' => { error: 'Name is required' } } },
             { code: 401, message: 'Unauthorized' },
             { code: 422, message: 'Unprocessable Entity' }
           ],
           tags: ['pets']
      params do
        requires :name, type: String, desc: 'Pet name (1-100 characters)'
        requires :pet_type, type: String, values: %w[dog cat bird], desc: 'Type of pet'
        optional :birth_date, type: DateTime, desc: 'Birth date in ISO 8601 format', allow_blank: true
        optional :weight, type: Float, desc: 'Weight in kilograms', allow_blank: true

        # Dog-specific params
        given pet_type: ->(val) { val == 'dog' } do
          optional :breed, type: String, desc: 'Dog breed name'
          optional :is_trained, type: Boolean, default: false, desc: 'Whether the dog is trained'
          optional :favorite_toy, type: String, allow_blank: true, desc: 'Name of favorite toy'
        end

        # Cat-specific params
        given pet_type: ->(val) { val == 'cat' } do
          optional :color, type: String, desc: 'Primary coat color'
          optional :is_indoor, type: Boolean, default: true, desc: 'Whether the cat lives indoors'
          optional :hunting_skill, type: Integer, values: 1..10, desc: 'Hunting skill level (1-10)'
        end

        # Bird-specific params
        given pet_type: ->(val) { val == 'bird' } do
          optional :species, type: String, desc: 'Bird species name'
          optional :can_fly, type: Boolean, default: true, desc: 'Whether the bird can fly'
          optional :wingspan_cm, type: Float, allow_blank: true, desc: 'Wingspan in centimeters'
        end
      end
      post do
        pet = declared(params).merge(id: rand(1000..9999), created_at: Time.now, updated_at: Time.now)

        entity = case params[:pet_type]
                 when 'dog' then Entities::Dog
                 when 'cat' then Entities::Cat
                 when 'bird' then Entities::Bird
                 else Entities::Pet
                 end

        present pet, with: entity
      end

      desc 'Update a pet',
           summary: 'Modify pet information',
           detail: 'Updates an existing pet record with the provided fields.',
           success: {
             model: Entities::Pet,
             examples: {
               'application/json' => { id: 1, name: 'Buddy Updated', pet_type: 'dog',
                                       updated_at: '2024-01-15T12:00:00Z' }
             }
           },
           failure: [
             { code: 400, message: 'Validation error' },
             { code: 404, message: 'Pet not found' }
           ],
           tags: ['pets']
      params do
        requires :id, type: Integer, values: 1..2_147_483_647, desc: 'Unique pet identifier'
        optional :name, type: String, desc: 'New pet name'
        optional :weight, type: Float, allow_blank: true, desc: 'Weight in kilograms'
        optional :birth_date, type: DateTime, allow_blank: true, desc: 'Birth date in ISO 8601 format'
      end
      put ':id' do
        pet = { id: params[:id], name: params[:name] || 'Buddy', pet_type: 'dog', updated_at: Time.now }
        present pet, with: Entities::Pet
      end

      desc 'Delete a pet',
           summary: 'Remove a pet record',
           detail: 'Permanently deletes a pet from the system.',
           failure: [
             { code: 404, message: 'Pet not found' },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['pets']
      params do
        requires :id, type: Integer, values: 1..2_147_483_647, desc: 'Unique pet identifier'
      end
      delete ':id' do
        status 204
        body false
      end
    end
  end
end
