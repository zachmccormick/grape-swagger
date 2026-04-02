# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Builds Header Objects for OpenAPI 3.1.0
    # Transforms Swagger 2.0 style headers to proper OpenAPI 3.1.0 Header Object format
    class HeaderBuilder
      # Fields that should be at the header level (not in schema)
      HEADER_LEVEL_FIELDS = %i[
        description
        required
        deprecated
        allowEmptyValue
        style
        explode
        allowReserved
        example
        examples
        content
      ].freeze

      # Fields that should be moved into the schema object
      SCHEMA_FIELDS = %i[
        type
        format
        enum
        default
        minimum
        maximum
        minLength
        maxLength
        pattern
        items
      ].freeze

      class << self
        # Builds response headers for OpenAPI 3.1.0
        #
        # @param headers [Hash] Headers hash with header names as keys
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] Transformed headers for OpenAPI 3.1.0 or original for Swagger 2.0
        def build(headers, version)
          return headers unless version.openapi_3_1_0?
          return nil if headers.nil? || headers.empty?

          headers.transform_values do |header_def|
            build_header_object(header_def, version)
          end
        end

        private

        # Builds a single Header Object for OpenAPI 3.1.0
        #
        # @param header_def [Hash] Header definition
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Proper Header Object
        def build_header_object(header_def, _version)
          return header_def unless header_def.is_a?(Hash)

          # If already has schema, it's already in 3.1.0 format
          return header_def if header_def[:schema] || header_def['schema']

          result = {}

          # Extract header-level fields
          HEADER_LEVEL_FIELDS.each do |field|
            value = header_def[field] || header_def[field.to_s]
            result[field] = value if value
          end

          # Check if content is present - content and schema are mutually exclusive
          has_content = result.key?(:content)

          unless has_content
            # Build schema from remaining fields
            schema = build_schema(header_def)
            result[:schema] = schema unless schema.empty?

            # Set default style for headers (simple)
            result[:style] ||= 'simple' if result[:schema]

            # Set default explode for headers (false for simple style)
            add_explode_default(result, header_def) if result[:schema]

            # Add allowReserved if explicitly set
            add_allow_reserved(result, header_def)
          end

          result.empty? ? header_def : result
        end

        # Adds default explode value for headers
        #
        # @param result [Hash] Result header object
        # @param header_def [Hash] Original header definition
        def add_explode_default(result, header_def)
          # Use explicit value if provided
          if header_def.key?(:explode) || header_def.key?('explode')
            result[:explode] = header_def[:explode] || header_def['explode']
            return
          end

          # Only add explode for arrays and objects
          schema_type = result.dig(:schema, :type)
          return unless %w[array object].include?(schema_type)

          # Headers use simple style by default, which has explode=false
          result[:explode] = false
        end

        # Adds allowReserved if explicitly set
        #
        # @param result [Hash] Result header object
        # @param header_def [Hash] Original header definition
        def add_allow_reserved(result, header_def)
          value = header_def[:allowReserved] || header_def['allowReserved']
          result[:allowReserved] = value unless value.nil?
        end

        # Extracts schema fields from header definition
        #
        # @param header_def [Hash] Header definition
        # @return [Hash] Schema object
        def build_schema(header_def)
          schema = {}

          SCHEMA_FIELDS.each do |field|
            value = header_def[field] || header_def[field.to_s]
            schema[field] = value if value
          end

          # Default to string type if no type specified but other fields present
          schema[:type] ||= 'string' if schema.any?

          schema
        end
      end
    end
  end
end
