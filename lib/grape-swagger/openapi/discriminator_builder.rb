# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Builds OpenAPI 3.1.0 discriminator objects.
    # Swagger 2.0 discriminators (simple propertyName strings) are handled
    # natively by grape-swagger's existing definition logic.
    class DiscriminatorBuilder
      class << self
        # Builds discriminator object for OpenAPI 3.1.0
        #
        # @param discriminator_config [Hash, nil] Discriminator configuration
        # @return [Hash, nil] Discriminator object with propertyName and optional mapping
        def build(discriminator_config)
          return nil unless discriminator_config
          return nil if discriminator_config.empty?

          result = {
            propertyName: discriminator_config[:property_name]
          }

          result[:mapping] = build_mapping(discriminator_config[:mapping]) if discriminator_config[:mapping]

          result
        end

        private

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
