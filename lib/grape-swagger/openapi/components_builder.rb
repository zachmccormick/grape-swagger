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
          components[:securitySchemes] = transform_security_schemes(options[:securityDefinitions], version)
        end

        # Translate references if version is provided and it's OpenAPI 3.1.0
        components = translate_component_references(components, version) if version && !version.swagger_2_0?

        # Only include keys that have values
        components.select { |_key, value| value && !value.empty? }
      end

      def self.transform_security_schemes(security_definitions, version)
        return security_definitions.dup unless version && !version.swagger_2_0?

        security_definitions.each_with_object({}) do |(name, config), result|
          transformed = SecuritySchemeBuilder.build(config, version)
          result[name] = transformed if transformed
        end
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
