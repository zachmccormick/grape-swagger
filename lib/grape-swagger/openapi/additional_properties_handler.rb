# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # AdditionalPropertiesHandler manages additionalProperties, unevaluatedProperties, and patternProperties
    #
    # OpenAPI 3.1.0 supports:
    # - additionalProperties: boolean or schema to control extra properties
    # - unevaluatedProperties: like additionalProperties but for composition (allOf, etc.)
    # - patternProperties: schema constraints based on property name patterns
    #
    # @example Strict object (no additional properties)
    #   schema = { type: 'object', properties: { name: { type: 'string' } } }
    #   AdditionalPropertiesHandler.apply(schema, version, additional_properties: false)
    #   # => { type: 'object', properties: {...}, additionalProperties: false }
    #
    # @example Pattern properties for dynamic keys
    #   AdditionalPropertiesHandler.apply(
    #     schema,
    #     version,
    #     pattern_properties: { '^x-': { type: 'string' } }
    #   )
    class AdditionalPropertiesHandler
      # Applies additional properties controls to a schema
      #
      # @param schema [Hash] The schema to modify
      # @param version [GrapeSwagger::OpenAPI::Version] The version object
      # @param options [Hash] Options for controlling additional properties
      # @option options [Boolean, Hash] :additional_properties Control additionalProperties
      # @option options [Boolean, Hash] :unevaluated_properties Control unevaluatedProperties (3.1.0 only)
      # @option options [Hash] :pattern_properties Pattern-based property schemas
      # @return [Hash] Modified schema
      def self.apply(schema, version, options = {})
        return schema unless schema.is_a?(Hash)

        # Only apply to object types
        # Don't apply to schemas with a non-object type, or schemas without any content
        return schema if schema[:type] && schema[:type] != 'object'
        return schema if schema.empty?

        result = deep_dup(schema)

        # Apply additionalProperties
        apply_additional_properties(result, options)

        # Apply unevaluatedProperties (OpenAPI 3.1.0 only)
        apply_unevaluated_properties(result, version, options)

        # Apply patternProperties
        apply_pattern_properties(result, version, options)

        result
      end

      private_class_method def self.apply_additional_properties(schema, options)
        return unless options.key?(:additional_properties)

        additional_props = options[:additional_properties]

        # Handle both boolean and schema values
        if additional_props.is_a?(Hash)
          schema[:additionalProperties] = additional_props
        else
          schema[:additionalProperties] = additional_props
        end
      end

      private_class_method def self.apply_unevaluated_properties(schema, version, options)
        return unless options.key?(:unevaluated_properties)
        return unless version.openapi_3_1_0?

        unevaluated_props = options[:unevaluated_properties]

        # Handle both boolean and schema values
        if unevaluated_props.is_a?(Hash)
          schema[:unevaluatedProperties] = unevaluated_props
        else
          schema[:unevaluatedProperties] = unevaluated_props
        end
      end

      private_class_method def self.apply_pattern_properties(schema, version, options)
        return unless options.key?(:pattern_properties)

        patterns = options[:pattern_properties]
        return unless patterns.is_a?(Hash)

        if version.swagger_2_0?
          # Use extension for Swagger 2.0
          schema[:'x-patternProperties'] = patterns
        else
          # Native support in OpenAPI 3.1.0
          schema[:patternProperties] = patterns
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
