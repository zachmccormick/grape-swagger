# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # TypeMapper provides JSON Schema 2020-12 compliant type mappings for OpenAPI 3.1.0.
    #
    # Key Differences from Swagger 2.0 (handled by DataType::PRIMITIVE_MAPPINGS):
    # - Integer/Number types: No format specifiers (JSON Schema 2020-12 removes int32, int64, float, double)
    # - Binary data: Uses contentEncoding and contentMediaType instead of format
    # - String formats: email, uuid, uri, etc. are annotations only
    # - Type arrays: Supports union types like {type: ['string', 'number']}
    #
    # @example Basic type mapping
    #   TypeMapper.map('integer')
    #   # => {type: 'integer'}
    #
    # @example Binary type with contentEncoding
    #   TypeMapper.map('binary')
    #   # => {type: 'string', contentEncoding: 'base64', contentMediaType: 'application/octet-stream'}
    #
    # @example Type array for union types
    #   TypeMapper.map_with_type_array(['string', 'number'])
    #   # => {type: ['string', 'number']}
    class TypeMapper
      # OpenAPI 3.1.0 type mappings following JSON Schema 2020-12
      OPENAPI_3_1_TYPES = {
        'integer' => { type: 'integer' },
        'long' => { type: 'integer', minimum: -2**63, maximum: (2**63) - 1 },
        'float' => { type: 'number' },
        'double' => { type: 'number' },
        'string' => { type: 'string' },
        'byte' => {
          type: 'string',
          contentEncoding: 'base64'
        },
        'binary' => {
          type: 'string',
          contentEncoding: 'base64',
          contentMediaType: 'application/octet-stream'
        },
        'boolean' => { type: 'boolean' },
        'date' => { type: 'string', format: 'date' },
        'dateTime' => { type: 'string', format: 'date-time' },
        'password' => { type: 'string', format: 'password' },
        'email' => { type: 'string', format: 'email' },
        'uuid' => { type: 'string', format: 'uuid' },
        'uri' => { type: 'string', format: 'uri' },
        'hostname' => { type: 'string', format: 'hostname' },
        'ipv4' => { type: 'string', format: 'ipv4' },
        'ipv6' => { type: 'string', format: 'ipv6' }
      }.freeze

      # Maps a Grape type to the appropriate OpenAPI 3.1.0 schema type
      #
      # @param grape_type [String] The Grape/internal type name
      # @return [Hash] Type mapping as a JSON Schema 2020-12 object
      def self.map(grape_type)
        OPENAPI_3_1_TYPES[grape_type] || { type: 'string' }
      end

      # Maps a type with support for type arrays (OpenAPI 3.1.0 feature)
      #
      # @param types [String, Array<String>] Single type or array of types
      # @return [Hash] Type mapping
      def self.map_with_type_array(types)
        if types.is_a?(Array)
          raise ArgumentError, 'Type array cannot be empty' if types.empty?

          { type: types.uniq }
        else
          map(types)
        end
      end

      # Converts a type mapping to JSON Schema format
      # (Pass-through since we're already JSON Schema 2020-12 compliant)
      #
      # @param mapping [Hash] The type mapping from map() or map_with_type_array()
      # @return [Hash] JSON Schema compatible type definition
      def self.to_json_schema_type(mapping)
        mapping
      end
    end
  end
end
