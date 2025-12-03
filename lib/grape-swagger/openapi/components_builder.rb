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
        pathItems
      ].freeze

      def self.build(options)
        components = {}
        version = options[:version]

        # Start with auto-registered reusable components
        registered = GrapeSwagger::ComponentsRegistry.to_openapi
        registered.each do |key, value|
          components[key] = value.dup if value && !value.empty?
        end

        # Merge explicit components (takes precedence)
        options[:components]&.each do |key, value|
          components[key] = if components[key]
                              components[key].merge(value)
                            else
                              value.dup
                            end
        end

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

        # Transform security schemes if version is provided
        if version && components[:securitySchemes]
          components[:securitySchemes] = transform_security_schemes(components[:securitySchemes], version)
        end

        # Translate references if version is provided and it's OpenAPI 3.1.0
        components = translate_component_references(components, version) if version && !version.swagger_2_0?

        # Only include keys that have values
        components.select { |_key, value| value && !value.empty? }
      end

      def self.transform_security_schemes(security_schemes, version)
        return security_schemes unless security_schemes.is_a?(Hash)

        transformed = {}
        security_schemes.each do |scheme_name, scheme_config|
          result = SecuritySchemeBuilder.build(scheme_config, version)
          # Only include the scheme if it's not nil (some schemes aren't supported in Swagger 2.0)
          transformed[scheme_name] = result if result
        end
        transformed
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
