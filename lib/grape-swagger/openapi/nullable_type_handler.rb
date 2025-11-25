# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # NullableTypeHandler transforms nullable: true to type arrays for OpenAPI 3.1.0
    #
    # OpenAPI 3.1.0 uses JSON Schema 2020-12 which does not support nullable.
    # Instead, it uses type arrays: {type: ['string', 'null']}
    #
    # @example Transform nullable string
    #   schema = {type: 'string', nullable: true}
    #   NullableTypeHandler.transform(schema, version)
    #   # => {type: ['string', 'null']}
    #
    # @example Swagger 2.0 preserves nullable
    #   schema = {type: 'string', nullable: true}
    #   NullableTypeHandler.transform(schema, swagger_2_0_version)
    #   # => {type: 'string', nullable: true}
    class NullableTypeHandler
      # Transforms nullable: true to type arrays for OpenAPI 3.1.0
      #
      # @param schema [Hash] The schema to transform
      # @param version [GrapeSwagger::OpenAPI::Version] The version object
      # @return [Hash] Transformed schema
      def self.transform(schema, version)
        return schema unless version.openapi_3_1_0?
        return schema if schema[:nullable].nil?

        result = schema.dup
        nullable = result.delete(:nullable)

        # Only transform if nullable is true
        return result unless nullable

        # If there's a type, make it an array with 'null'
        if result[:type]
          result[:type] = normalize_type_array(result[:type])
        end

        result
      end

      # Normalizes a type to an array including 'null'
      #
      # @param type [String, Array<String>] The type or types
      # @return [Array<String>] Type array with 'null'
      def self.normalize_type_array(type)
        types = Array(type)
        types << 'null' unless types.include?('null')
        types.uniq
      end

      private_class_method :normalize_type_array
    end
  end
end
