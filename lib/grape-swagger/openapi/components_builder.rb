# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class ComponentsBuilder
      COMPONENT_KEYS = %i[
        schemas
        responses
        parameters
        examples
        requestBodies
        headers
        securitySchemes
        links
        callbacks
      ].freeze

      def self.build(options)
        components = {}

        # Start with explicit components if provided
        components = options[:components].dup if options[:components]

        # Handle legacy definitions -> schemas
        if options[:definitions]
          # Prefer explicit components.schemas over legacy definitions
          components[:schemas] = options[:definitions].dup unless components[:schemas]
        end

        # Handle legacy securityDefinitions -> securitySchemes
        if options[:securityDefinitions]
          # Prefer explicit components.securitySchemes over legacy securityDefinitions
          components[:securitySchemes] = options[:securityDefinitions].dup unless components[:securitySchemes]
        end

        # Only include keys that have values
        components.select { |_key, value| value && !value.empty? }
      end
    end
  end
end
