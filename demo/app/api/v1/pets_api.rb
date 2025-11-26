# frozen_string_literal: true

module V1
  class PetsAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :pets do
      desc 'List all pets',
           is_array: true,
           success: { model: Entities::Pet, message: 'List of pets' },
           failure: [
             { code: 401, message: 'Unauthorized' },
             { code: 500, message: 'Internal Server Error' }
           ],
           tags: ['pets']
      params do
        optional :type, type: String, values: %w[dog cat bird], desc: 'Filter by pet type'
        optional :limit, type: Integer, default: 20, desc: 'Number of results'
        optional :offset, type: Integer, default: 0, desc: 'Offset for pagination'
      end
      get do
        # Demo data
        pets = [
          { id: 1, name: 'Buddy', pet_type: 'dog', breed: 'Golden Retriever', is_trained: true },
          { id: 2, name: 'Whiskers', pet_type: 'cat', color: 'orange', is_indoor: true },
          { id: 3, name: 'Tweety', pet_type: 'bird', species: 'Canary', can_fly: true }
        ]

        if params[:type]
          pets = pets.select { |p| p[:pet_type] == params[:type] }
        end

        present pets, with: Entities::Pet
      end

      desc 'Get a pet by ID',
           success: { model: Entities::Pet },
           failure: [
             { code: 404, message: 'Pet not found' },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['pets']
      params do
        requires :id, type: Integer, desc: 'Pet ID'
      end
      get ':id' do
        pet = { id: params[:id], name: 'Buddy', pet_type: 'dog', breed: 'Golden Retriever' }
        present pet, with: Entities::Dog
      end

      desc 'Create a new pet',
           success: { model: Entities::Pet, message: 'Pet created' },
           failure: [
             { code: 400, message: 'Validation error' },
             { code: 401, message: 'Unauthorized' },
             { code: 422, message: 'Unprocessable Entity' }
           ],
           tags: ['pets']
      params do
        requires :name, type: String, desc: 'Pet name'
        requires :pet_type, type: String, values: %w[dog cat bird], desc: 'Pet type'
        optional :birth_date, type: DateTime, desc: 'Birth date (nullable)', allow_blank: true
        optional :weight, type: Float, desc: 'Weight in kg (nullable)', allow_blank: true

        # Dog-specific params
        given pet_type: ->(val) { val == 'dog' } do
          optional :breed, type: String, desc: 'Dog breed'
          optional :is_trained, type: Boolean, default: false
          optional :favorite_toy, type: String, allow_blank: true
        end

        # Cat-specific params
        given pet_type: ->(val) { val == 'cat' } do
          optional :color, type: String, desc: 'Cat color'
          optional :is_indoor, type: Boolean, default: true
          optional :hunting_skill, type: Integer, values: (1..10).to_a
        end

        # Bird-specific params
        given pet_type: ->(val) { val == 'bird' } do
          optional :species, type: String, desc: 'Bird species'
          optional :can_fly, type: Boolean, default: true
          optional :wingspan_cm, type: Float, allow_blank: true
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
           success: { model: Entities::Pet },
           failure: [
             { code: 400, message: 'Validation error' },
             { code: 404, message: 'Pet not found' }
           ],
           tags: ['pets']
      params do
        requires :id, type: Integer, desc: 'Pet ID'
        optional :name, type: String
        optional :weight, type: Float, allow_blank: true
        optional :birth_date, type: DateTime, allow_blank: true
      end
      put ':id' do
        pet = { id: params[:id], name: params[:name] || 'Buddy', pet_type: 'dog', updated_at: Time.now }
        present pet, with: Entities::Pet
      end

      desc 'Delete a pet',
           failure: [
             { code: 404, message: 'Pet not found' },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['pets']
      params do
        requires :id, type: Integer, desc: 'Pet ID'
      end
      delete ':id' do
        status 204
        body false
      end
    end
  end
end
