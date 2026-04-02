# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class DiscriminatorBuilder
      class << self
        # Builds discriminator object for OpenAPI 3.1.0 or Swagger 2.0
        #
        # @param discriminator_config [Hash, nil] Discriminator configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, String, nil] Discriminator object or nil
        def build(discriminator_config, version)
          return nil unless discriminator_config
          return nil if discriminator_config.empty?

          if version.swagger_2_0?
            build_swagger_2_0(discriminator_config)
          else
            build_openapi_3_1(discriminator_config)
          end
        end

        private

        # Build OpenAPI 3.1.0 discriminator object
        #
        # @param config [Hash] Discriminator configuration
        # @return [Hash] Discriminator object with propertyName and optional mapping
        def build_openapi_3_1(config)
          result = {
            propertyName: config[:property_name]
          }

          result[:mapping] = build_mapping(config[:mapping]) if config[:mapping]

          result
        end

        # Build Swagger 2.0 discriminator (simpler format)
        # Swagger 2.0 only supports propertyName as a string
        #
        # @param config [Hash] Discriminator configuration
        # @return [String] Property name string
        def build_swagger_2_0(config)
          config[:property_name]
        end

        # Build mapping hash with normalized refs
        #
        # @param mapping [Hash] Mapping configuration
        # @return [Hash] Normalized mapping hash
        def build_mapping(mapping)
          mapping.transform_values do |ref|
            normalize_ref(ref)
          end
        end

        # Normalize a reference to a schema ref
        # - If ref starts with '#', it's already a local ref - keep it
        # - If ref starts with 'http://' or 'https://', it's an external ref - keep it
        # - Otherwise, convert to component ref
        #
        # @param ref [String] Reference value
        # @return [String] Normalized reference
        def normalize_ref(ref)
          return ref if ref.start_with?('#')
          return ref if ref.start_with?('http://', 'https://')

          "#/components/schemas/#{ref}"
        end
      end
    end
  end
end
