# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # DependentSchemaHandler transforms dependencies to dependentSchemas/dependentRequired for OpenAPI 3.1.0
    #
    # OpenAPI 3.1.0 uses JSON Schema 2020-12 which replaces the legacy 'dependencies' keyword with:
    # - dependentSchemas: when a property presence requires specific schema constraints
    # - dependentRequired: when a property presence requires other properties
    #
    # @example Array dependency (required fields)
    #   schema = { dependencies: { email: ['name'] } }
    #   DependentSchemaHandler.transform(schema, version)
    #   # => { dependentRequired: { email: ['name'] } }
    #
    # @example Schema dependency (additional constraints)
    #   schema = {
    #     dependencies: {
    #       phone: {
    #         properties: { phone_type: { type: 'string' } },
    #         required: ['phone_type']
    #       }
    #     }
    #   }
    #   # => { dependentSchemas: { phone: { properties: {...}, required: [...] } } }
    class DependentSchemaHandler
      # Transforms dependencies to OpenAPI 3.1.0 format
      #
      # @param schema [Hash] The schema to transform
      # @param version [GrapeSwagger::OpenAPI::Version] The version object
      # @return [Hash] Transformed schema
      def self.transform(schema, version)
        return schema unless schema.is_a?(Hash)

        # For Swagger 2.0, keep dependencies as-is (supported)
        return schema unless version.openapi_3_1_0?

        result = deep_dup(schema)

        # Convert legacy dependencies to new format
        convert_dependencies(result) if result[:dependencies]

        # Process nested schemas recursively
        process_nested_schemas(result, version)

        result
      end

      private_class_method def self.convert_dependencies(schema)
        deps = schema.delete(:dependencies)
        return if deps.nil? || deps.empty?

        deps.each do |prop, value|
          if value.is_a?(Array)
            # Array of property names -> dependentRequired
            schema[:dependentRequired] ||= {}
            schema[:dependentRequired][prop] = value
          elsif value.is_a?(Hash)
            # Schema object -> dependentSchemas
            schema[:dependentSchemas] ||= {}
            schema[:dependentSchemas][prop] = value
          end
        end
      end

      private_class_method def self.process_nested_schemas(schema, version)
        # Process properties
        if schema[:properties].is_a?(Hash)
          schema[:properties].each do |key, value|
            schema[:properties][key] = transform(value, version) if value.is_a?(Hash)
          end
        end

        # Process dependentSchemas
        if schema[:dependentSchemas].is_a?(Hash)
          schema[:dependentSchemas].each do |key, value|
            schema[:dependentSchemas][key] = transform(value, version) if value.is_a?(Hash)
          end
        end

        # Process composition keywords
        %i[allOf oneOf anyOf].each do |keyword|
          next unless schema[keyword].is_a?(Array)

          schema[keyword] = schema[keyword].map do |s|
            s.is_a?(Hash) ? transform(s, version) : s
          end
        end
      end

      private_class_method def self.deep_dup(hash)
        return hash unless hash.is_a?(Hash)

        hash.transform_values do |value|
          case value
          when Hash
            deep_dup(value)
          when Array
            value.map { |v| v.is_a?(Hash) ? deep_dup(v) : v }
          else
            value
          end
        end
      end
    end
  end
end
