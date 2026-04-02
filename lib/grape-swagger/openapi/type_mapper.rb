# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # TypeMapper handles type mapping for different OpenAPI/Swagger versions.
    # Provides JSON Schema 2020-12 compliant type mappings for OpenAPI 3.1.0.
    #
    # Key Differences for OpenAPI 3.1.0:
    # - Integer/Number types: No format specifiers (JSON Schema 2020-12 removes int32, int64, float, double)
    # - Binary data: Uses contentEncoding and contentMediaType instead of format
    # - String formats: email, uuid, uri, etc. are annotations only
    # - Type arrays: Supports union types like {type: ['string', 'number']}
    #
    # @example Basic type mapping
    #   TypeMapper.map('integer', '3.1.0')
    #   # => {type: 'integer'}
    #
    # @example Binary type with contentEncoding
    #   TypeMapper.map('binary', '3.1.0')
    #   # => {type: 'string', contentEncoding: 'base64', contentMediaType: 'application/octet-stream'}
    #
    # @example Type array for union types
    #   TypeMapper.map_with_type_array(['string', 'number'], '3.1.0')
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

      # Swagger 2.0 type mappings (legacy format: [type, format])
      SWAGGER_2_0_TYPES = {
        'integer' => %w[integer int32],
        'long' => %w[integer int64],
        'float' => %w[number float],
        'double' => %w[number double],
        'string' => 'string',
        'byte' => %w[string byte],
        'binary' => %w[string binary],
        'boolean' => 'boolean',
        'date' => %w[string date],
        'dateTime' => %w[string date-time],
        'password' => %w[string password],
        'email' => %w[string email],
        'uuid' => %w[string uuid]
      }.freeze

      # Maps a Grape type to the appropriate schema type based on version
      #
      # @param grape_type [String] The Grape/internal type name
      # @param version [String] The OpenAPI/Swagger version ('3.1.0' or '2.0')
      # @return [Hash, Array, String] Type mapping based on version
      def self.map(grape_type, version = '3.1.0')
        return map_swagger_2_0(grape_type) if version == '2.0'

        OPENAPI_3_1_TYPES[grape_type] || { type: 'string' }
      end

      # Maps a type with support for type arrays (OpenAPI 3.1.0 only)
      #
      # @param types [String, Array<String>] Single type or array of types
      # @param version [String] The OpenAPI/Swagger version
      # @return [Hash, String] Type mapping
      def self.map_with_type_array(types, version = '3.1.0')
        # Swagger 2.0 doesn't support type arrays
        return map_swagger_2_0(types.is_a?(Array) ? types.first : types) if version == '2.0'

        if types.is_a?(Array)
          raise ArgumentError, 'Type array cannot be empty' if types.empty?

          # Deduplicate types
          unique_types = types.uniq

          # Return type array without format
          { type: unique_types }
        else
          # Single type - use normal mapping
          map(types, version)
        end
      end

      # Converts a type mapping to JSON Schema format
      # (For OpenAPI 3.1.0, this is mostly a pass-through since we're already JSON Schema compliant)
      #
      # @param mapping [Hash] The type mapping from map() or map_with_type_array()
      # @return [Hash] JSON Schema compatible type definition
      def self.to_json_schema_type(mapping)
        # Already in JSON Schema 2020-12 format for OpenAPI 3.1.0
        mapping
      end

      # Maps types for Swagger 2.0 (legacy format)
      #
      # @param grape_type [String] The Grape/internal type name
      # @return [Array, String] Legacy [type, format] array or simple string
      def self.map_swagger_2_0(grape_type)
        SWAGGER_2_0_TYPES[grape_type] || 'string'
      end

      private_class_method :map_swagger_2_0
    end
  end
end
