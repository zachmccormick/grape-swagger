# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # BinaryDataEncoder transforms binary/byte formats to contentEncoding for OpenAPI 3.1.0
    #
    # OpenAPI 3.1.0 uses JSON Schema 2020-12 which uses contentEncoding and contentMediaType
    # instead of format: 'binary' or format: 'byte'
    #
    # @example Transform binary format
    #   schema = {type: 'string', format: 'binary'}
    #   BinaryDataEncoder.encode(schema, version)
    #   # => {type: 'string', contentEncoding: 'base64', contentMediaType: 'application/octet-stream'}
    #
    # @example Transform byte format
    #   schema = {type: 'string', format: 'byte'}
    #   BinaryDataEncoder.encode(schema, version)
    #   # => {type: 'string', contentEncoding: 'base64'}
    #
    # @example Swagger 2.0 preserves format
    #   schema = {type: 'string', format: 'binary'}
    #   BinaryDataEncoder.encode(schema, swagger_2_0_version)
    #   # => {type: 'string', format: 'binary'}
    class BinaryDataEncoder
      # Binary format encodings for OpenAPI 3.1.0
      BINARY_ENCODINGS = {
        'binary' => {
          contentEncoding: 'base64',
          contentMediaType: 'application/octet-stream'
        },
        'byte' => {
          contentEncoding: 'base64'
        }
      }.freeze

      # Encodes binary/byte formats to contentEncoding for OpenAPI 3.1.0
      #
      # @param schema [Hash] The schema to encode
      # @param version [GrapeSwagger::OpenAPI::Version] The version object
      # @return [Hash] Encoded schema
      def self.encode(schema, version)
        return schema unless version.openapi_3_1_0?

        format = schema[:format]
        return schema unless format && BINARY_ENCODINGS.key?(format)

        result = schema.dup
        result.delete(:format)

        # Preserve custom contentMediaType if already present
        encoding = BINARY_ENCODINGS[format].dup
        if result[:contentMediaType]
          encoding[:contentMediaType] = result[:contentMediaType]
        end

        result.merge(encoding)
      end
    end
  end
end
