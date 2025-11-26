# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class PolymorphicSchemaBuilder
      class << self
        # Build oneOf schema for exclusive alternatives
        # Only supported in OpenAPI 3.1.0+
        #
        # @param schemas [Array] Array of schema names, refs, or inline schemas
        # @param discriminator [Hash, nil] Optional discriminator configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] oneOf schema object or nil
        def build_one_of(schemas, discriminator, version)
          return nil unless version.openapi_3_1_0?

          result = {
            oneOf: schemas.map { |s| normalize_schema_ref(s) }
          }

          result[:discriminator] = DiscriminatorBuilder.build(discriminator, version) if discriminator

          result
        end

        # Build anyOf schema for flexible matching
        # Only supported in OpenAPI 3.1.0+
        #
        # @param schemas [Array] Array of schema names, refs, or inline schemas
        # @param discriminator [Hash, nil] Optional discriminator configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] anyOf schema object or nil
        def build_any_of(schemas, discriminator, version)
          return nil unless version.openapi_3_1_0?

          result = {
            anyOf: schemas.map { |s| normalize_schema_ref(s) }
          }

          result[:discriminator] = DiscriminatorBuilder.build(discriminator, version) if discriminator

          result
        end

        # Build allOf schema for entity inheritance
        # Supported in both Swagger 2.0 and OpenAPI 3.1.0
        #
        # @param base_schema [String, Hash] Base schema name or ref object
        # @param extension_schema [Hash] Extension schema with additional properties
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] allOf schema object
        def build_all_of(base_schema, extension_schema, _version)
          {
            allOf: [
              normalize_schema_ref(base_schema),
              extension_schema
            ]
          }
        end

        private

        # Normalize a schema reference
        # - If it's a Hash with '$ref' key, return as-is
        # - If it's a Hash without '$ref', it's an inline schema, return as-is
        # - If it's a String, convert to component ref
        #
        # @param schema [String, Hash] Schema name, ref object, or inline schema
        # @return [Hash] Normalized schema reference or inline schema
        def normalize_schema_ref(schema)
          return schema if schema.is_a?(Hash)

          { '$ref' => "#/components/schemas/#{schema}" }
        end
      end
    end
  end
end
