# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class ParameterSchemaWrapper
      # Fields that should be moved into the schema object for OpenAPI 3.1.0
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
        minItems
        maxItems
        uniqueItems
        multipleOf
        exclusiveMinimum
        exclusiveMaximum
        readOnly
        writeOnly
        minProperties
        maxProperties
        title
        not
        externalDocs
      ].freeze

      # Fields that should remain at the parameter level
      NON_SCHEMA_FIELDS = %i[
        name
        in
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

      # Default style values per parameter location
      DEFAULT_STYLES = {
        query: 'form',
        path: 'simple',
        header: 'simple',
        cookie: 'form'
      }.freeze

      class << self
        # Wraps parameter schema fields for OpenAPI 3.1.0
        #
        # @param parameter [Hash] Parameter definition
        # @param version [GrapeSwagger::OpenAPI::Version] OpenAPI version
        # @return [Hash] Wrapped parameter
        def wrap(parameter, version)
          # Return unchanged for Swagger 2.0
          return parameter unless version.openapi_3_1_0?

          # Return $ref parameters as-is (component references)
          return parameter if parameter['$ref'] || parameter[:$ref]

          # Create a deep copy to avoid mutating the original and preserve all keys (symbol and string)
          wrapped = deep_copy(parameter)

          # Check if content is present - content and schema are mutually exclusive
          has_content = wrapped.key?(:content) || wrapped.key?('content')

          unless has_content
            # Extract schema fields
            schema = extract_schema_fields(wrapped)

            # Add schema object if there are schema fields
            wrapped[:schema] = schema unless schema.empty?
          end

          # Convert x-example to example for OpenAPI 3.1.0
          convert_example_extension(wrapped)

          # Add serialization options (only when using schema, not content)
          add_serialization_options(wrapped, parameter) unless has_content

          wrapped
        end

        private

        # Creates a deep copy of a hash to avoid mutating the original
        #
        # @param hash [Hash] Hash to copy
        # @return [Hash] Deep copy
        def deep_copy(hash)
          hash.transform_values do |value|
            value.is_a?(Hash) ? deep_copy(value) : value
          end
        end

        # Extracts schema fields from parameter
        #
        # @param param [Hash] Parameter definition
        # @return [Hash] Schema fields
        def extract_schema_fields(param)
          SCHEMA_FIELDS.each_with_object({}) do |field, schema|
            schema[field] = param.delete(field) if param.key?(field)
          end
        end

        # Adds serialization options (style, explode, allowReserved)
        #
        # @param wrapped [Hash] Wrapped parameter
        # @param original [Hash] Original parameter
        def add_serialization_options(wrapped, original)
          add_style(wrapped, original)
          add_explode(wrapped, original)
          add_allow_reserved(wrapped, original)
          add_allow_empty_value(wrapped, original)
        end

        # Adds the style field with appropriate default
        #
        # @param wrapped [Hash] Wrapped parameter
        # @param original [Hash] Original parameter
        def add_style(wrapped, original)
          # Use explicit style if provided
          if original.key?(:style)
            wrapped[:style] = original[:style]
            return
          end

          # Otherwise use default based on location
          location = wrapped[:in]&.to_sym
          wrapped[:style] = DEFAULT_STYLES[location] if DEFAULT_STYLES.key?(location)
        end

        # Adds the explode field with appropriate default
        #
        # @param wrapped [Hash] Wrapped parameter
        # @param original [Hash] Original parameter
        def add_explode(wrapped, original)
          # Use explicit explode if provided
          if original.key?(:explode)
            wrapped[:explode] = original[:explode]
            return
          end

          # Only add explode for arrays and objects
          schema_type = wrapped.dig(:schema, :type)
          return unless %w[array object].include?(schema_type)

          # Default explode based on style
          # form style: explode = true
          # simple style: explode = false
          # other styles: no default
          case wrapped[:style]
          when 'form'
            wrapped[:explode] = true
          when 'simple'
            wrapped[:explode] = false
          end
        end

        # Adds allowReserved if explicitly set
        #
        # @param wrapped [Hash] Wrapped parameter
        # @param original [Hash] Original parameter
        def add_allow_reserved(wrapped, original)
          wrapped[:allowReserved] = original[:allowReserved] if original.key?(:allowReserved)
        end

        # Adds allowEmptyValue if explicitly set
        #
        # @param wrapped [Hash] Wrapped parameter
        # @param original [Hash] Original parameter
        def add_allow_empty_value(wrapped, original)
          wrapped[:allowEmptyValue] = original[:allowEmptyValue] if original.key?(:allowEmptyValue)
        end

        # Converts x-example extension to standard example for OpenAPI 3.1.0
        # In Swagger 2.0, examples for non-body parameters use x-example extension
        # In OpenAPI 3.1.0, we use the standard example field
        #
        # @param wrapped [Hash] Wrapped parameter
        def convert_example_extension(wrapped)
          # Check for both symbol and string keys
          x_example_key = wrapped.key?(:'x-example') ? :'x-example' : 'x-example'
          return unless wrapped.key?(x_example_key)

          # Move x-example to example
          wrapped[:example] = wrapped.delete(x_example_key)
        end
      end
    end
  end
end
