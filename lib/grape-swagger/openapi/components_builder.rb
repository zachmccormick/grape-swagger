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
        version = options[:version]

        # Start with explicit components if provided
        components = options[:components].dup if options[:components]

        # Handle legacy definitions -> schemas
        if options[:definitions] && !components[:schemas]
          # Prefer explicit components.schemas over legacy definitions
          components[:schemas] = options[:definitions].dup
        end

        # Handle legacy securityDefinitions -> securitySchemes
        if options[:securityDefinitions] && !components[:securitySchemes]
          # Prefer explicit components.securitySchemes over legacy securityDefinitions
          components[:securitySchemes] = options[:securityDefinitions].dup
        end

        # Translate references if version is provided and it's OpenAPI 3.1.0
        if version && !version.swagger_2_0?
          components = translate_component_references(components, version)
        end

        # Only include keys that have values
        components.select { |_key, value| value && !value.empty? }
      end

      def self.translate_component_references(components, version)
        return components unless components.is_a?(Hash)

        translated = {}
        components.each do |key, value|
          translated[key] = if value.is_a?(Hash)
                              SchemaResolver.translate_components(value, version)
                            else
                              value
                            end
        end
        translated
      end
    end
  end
end
