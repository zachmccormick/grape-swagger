# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class SchemaResolver
      # Legacy Swagger 2.0 reference paths
      SWAGGER_2_PATHS = {
        'definitions' => 'definitions',
        'responses' => 'responses',
        'parameters' => 'parameters'
      }.freeze

      # OpenAPI 3.1.0 reference paths
      OPENAPI_3_PATHS = {
        'definitions' => 'components/schemas',
        'responses' => 'components/responses',
        'parameters' => 'components/parameters'
      }.freeze

      class << self
        # Translates a single $ref path based on the version
        #
        # @param ref [String] The reference path (e.g., '#/definitions/User')
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [String] The translated reference path
        def translate_ref(ref, version)
          return ref if version.swagger_2_0?
          return ref unless ref.is_a?(String)

          # Split external file path from internal reference
          if ref.include?('#')
            file_part, ref_part = ref.split('#', 2)
            translated_ref = translate_internal_ref(ref_part)
            file_part.empty? ? "##{translated_ref}" : "#{file_part}##{translated_ref}"
          else
            ref
          end
        end

        # Translates all references within a schema recursively
        #
        # @param schema [Hash] The schema object that may contain $ref
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] The schema with translated references
        def translate_schema(schema, version)
          return schema if version.swagger_2_0?
          return schema unless schema.is_a?(Hash)

          # Create a deep copy to avoid modifying the original
          result = deep_dup(schema)

          # Translate direct $ref (handle both string and symbol keys)
          ref_key = result.key?('$ref') ? '$ref' : (result.key?(:'$ref') ? :'$ref' : nil)
          if ref_key
            result[ref_key] = translate_ref(result[ref_key], version)
          end

          # Translate nested schemas
          translate_nested(result, version)

          result
        end

        # Translates all schemas within a components/definitions hash
        #
        # @param components [Hash] The components or definitions hash
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] The components with translated references
        def translate_components(components, version)
          return components if version.swagger_2_0?
          return components unless components.is_a?(Hash)

          result = {}
          components.each do |key, schema|
            result[key] = translate_schema(schema, version)
          end
          result
        end

        private

        # Translates internal reference paths (without file part)
        #
        # @param ref [String] The internal reference path (e.g., '/definitions/User')
        # @return [String] The translated internal reference path
        def translate_internal_ref(ref)
          return ref unless ref.start_with?('/')

          parts = ref.split('/')
          return ref if parts.length < 3

          # Check if it's already in OpenAPI 3.1.0 format
          return ref if parts[1] == 'components'

          # Translate from Swagger 2.0 to OpenAPI 3.1.0
          legacy_key = parts[1]
          if OPENAPI_3_PATHS.key?(legacy_key)
            new_path = OPENAPI_3_PATHS[legacy_key]
            parts[1..1] = new_path.split('/')
          end

          parts.join('/')
        end

        # Deep duplicate a hash
        def deep_dup(hash)
          return hash unless hash.is_a?(Hash)

          hash.each_with_object({}) do |(key, value), result|
            result[key] = case value
                          when Hash
                            deep_dup(value)
                          when Array
                            value.map { |v| v.is_a?(Hash) ? deep_dup(v) : v }
                          else
                            value
                          end
          end
        end

        # Get value from hash supporting both string and symbol keys
        def get_value(hash, key)
          hash[key] || hash[key.to_sym]
        end

        # Recursively translates nested schema structures
        #
        # @param schema [Hash] The schema object
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        def translate_nested(schema, version)
          # Handle properties (support both string and symbol keys)
          props_key = schema.key?('properties') ? 'properties' : (schema.key?(:properties) ? :properties : nil)
          if props_key && schema[props_key].is_a?(Hash)
            schema[props_key].each do |key, value|
              schema[props_key][key] = translate_schema(value, version)
            end
          end

          # Handle array items
          items_key = schema.key?('items') ? 'items' : (schema.key?(:items) ? :items : nil)
          if items_key && schema[items_key].is_a?(Hash)
            schema[items_key] = translate_schema(schema[items_key], version)
          end

          # Handle allOf, oneOf, anyOf
          %w[allOf oneOf anyOf].each do |keyword|
            key = schema.key?(keyword) ? keyword : (schema.key?(keyword.to_sym) ? keyword.to_sym : nil)
            if key && schema[key].is_a?(Array)
              schema[key] = schema[key].map { |s| translate_schema(s, version) }
            end
          end

          # Handle not
          not_key = schema.key?('not') ? 'not' : (schema.key?(:not) ? :not : nil)
          if not_key && schema[not_key].is_a?(Hash)
            schema[not_key] = translate_schema(schema[not_key], version)
          end

          # Handle additionalProperties
          add_props_key = schema.key?('additionalProperties') ? 'additionalProperties' : (schema.key?(:additionalProperties) ? :additionalProperties : nil)
          if add_props_key && schema[add_props_key].is_a?(Hash)
            schema[add_props_key] = translate_schema(schema[add_props_key], version)
          end
        end
      end
    end
  end
end
