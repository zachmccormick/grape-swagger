# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class EncodingBuilder
      class << self
        # Build encoding object for a single field
        #
        # @param field_name [Symbol, String] Field name
        # @param encoding_config [Hash, nil] Encoding configuration
        # @param version [GrapeSwagger::OpenAPI::Version] OpenAPI version
        # @return [Hash, nil] Encoding object or nil
        def build(field_name, encoding_config, version)
          return nil if encoding_config.nil? || encoding_config.empty?

          result = {}

          # Add contentType if present
          result[:contentType] = encoding_config[:contentType] if encoding_config[:contentType]

          # Add headers if present
          result[:headers] = encoding_config[:headers] if encoding_config[:headers]

          # Add style if present
          result[:style] = encoding_config[:style] if encoding_config[:style]

          # Add explode if present (include false values)
          result[:explode] = encoding_config[:explode] if encoding_config.key?(:explode)

          # Add allowReserved if present (include false values)
          result[:allowReserved] = encoding_config[:allowReserved] if encoding_config.key?(:allowReserved)

          result.empty? ? nil : result
        end

        # Build encoding for multiple fields
        #
        # @param encoding_config [Hash, nil] Hash of field name => encoding config
        # @param version [GrapeSwagger::OpenAPI::Version] OpenAPI version
        # @return [Hash, nil] Encoding object for all fields or nil
        def build_for_fields(encoding_config, version)
          return nil if encoding_config.nil? || encoding_config.empty?

          result = {}

          encoding_config.each do |field_name, field_config|
            encoding = build(field_name, field_config, version)
            result[field_name] = encoding if encoding
          end

          result.empty? ? nil : result
        end
      end
    end
  end
end
