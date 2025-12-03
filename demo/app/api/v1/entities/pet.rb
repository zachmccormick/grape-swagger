# frozen_string_literal: true

module V1
  module Entities
    # Base Pet entity demonstrating polymorphism
    # Used with discriminator to show Dog, Cat, or Bird
    class Pet < BaseEntity
      expose :id, documentation: { type: Integer, desc: 'Unique identifier' }
      expose :name, documentation: { type: String, desc: 'Pet name' }
      expose :pet_type, documentation: {
        type: String,
        desc: 'Type discriminator',
        values: %w[dog cat bird],
        is_discriminator: true # OpenAPI 3.1.0 discriminator support
      }
      expose :birth_date, documentation: {
        type: DateTime,
        desc: 'Birth date (nullable)',
        nullable: true
      }
      expose :weight, documentation: {
        type: Float,
        desc: 'Weight in kg (nullable)',
        nullable: true
      }
      expose :created_at, format_with: :iso_timestamp, documentation: { type: DateTime }
      expose :updated_at, format_with: :iso_timestamp, documentation: { type: DateTime }
    end

    # Dog entity extending Pet
    class Dog < Pet
      expose :breed, documentation: { type: String, desc: 'Dog breed' }
      expose :is_trained, documentation: { type: 'Boolean', desc: 'Is the dog trained?' }
      expose :favorite_toy, documentation: {
        type: String,
        desc: 'Favorite toy (nullable)',
        nullable: true
      }
    end

    # Cat entity extending Pet
    class Cat < Pet
      expose :color, documentation: { type: String, desc: 'Cat color' }
      expose :is_indoor, documentation: { type: 'Boolean', desc: 'Indoor cat?' }
      expose :hunting_skill, documentation: {
        type: Integer,
        desc: 'Hunting skill level 1-10',
        values: (1..10).to_a
      }
    end

    # Bird entity extending Pet
    class Bird < Pet
      expose :species, documentation: { type: String, desc: 'Bird species' }
      expose :can_fly, documentation: { type: 'Boolean', desc: 'Can the bird fly?' }
      expose :wingspan_cm, documentation: {
        type: Float,
        desc: 'Wingspan in centimeters (nullable)',
        nullable: true
      }
    end
  end
end
