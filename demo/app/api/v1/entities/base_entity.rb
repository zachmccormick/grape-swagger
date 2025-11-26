# frozen_string_literal: true

module V1
  module Entities
    class BaseEntity < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt&.iso8601 }
    end
  end
end
