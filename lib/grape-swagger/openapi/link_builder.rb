# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class LinkBuilder
      class << self
        # Builds links object for OpenAPI 3.1.0
        #
        # @param link_definitions [Hash] Hash of link definitions
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] Links object or nil
        def build(link_definitions, version)
          # Only OpenAPI 3.1.0 supports links
          return nil unless version.openapi_3_1_0?

          # Return nil if link_definitions is blank
          return nil if link_definitions.nil? || link_definitions.empty?

          # Build each link
          link_definitions.each_with_object({}) do |(name, config), links|
            links[name.to_s] = build_link(config)
          end
        end

        private

        # Build a single link definition
        #
        # @param config [Hash] Link configuration
        # @return [Hash] Link object
        def build_link(config)
          link = {}

          # Add operationId if present
          link[:operationId] = config[:operation_id] if config[:operation_id]

          # Add operationRef if present
          link[:operationRef] = config[:operation_ref] if config[:operation_ref]

          # Add parameters if present
          link[:parameters] = config[:parameters] if config[:parameters]

          # Add requestBody if present
          link[:requestBody] = config[:request_body] if config[:request_body]

          # Add description if present
          link[:description] = config[:description] if config[:description]

          # Add server if present
          link[:server] = config[:server] if config[:server]

          # Remove nil values
          link.compact
        end
      end
    end
  end
end
