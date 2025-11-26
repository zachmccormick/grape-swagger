# frozen_string_literal: true

module V1
  module Entities
    # User entity with various field types
    class User < BaseEntity
      expose :id, documentation: { type: Integer, desc: 'Unique identifier' }
      expose :email, documentation: { type: String, desc: 'Email address', format: 'email' }
      expose :name, documentation: { type: String, desc: 'Full name' }
      expose :role, documentation: {
        type: String,
        desc: 'User role',
        values: %w[admin moderator user guest]
      }
      expose :avatar_url, documentation: {
        type: String,
        desc: 'Avatar URL (nullable)',
        nullable: true,
        format: 'uri'
      }
      expose :bio, documentation: {
        type: String,
        desc: 'User biography (nullable)',
        nullable: true
      }
      expose :is_active, documentation: { type: 'Boolean', desc: 'Account active?' }
      expose :created_at, format_with: :iso_timestamp, documentation: { type: DateTime }
    end

    # Compact user representation
    class UserCompact < BaseEntity
      expose :id, documentation: { type: Integer }
      expose :name, documentation: { type: String }
      expose :email, documentation: { type: String, format: 'email' }
    end
  end
end
