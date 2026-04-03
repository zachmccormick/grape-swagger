# frozen_string_literal: true

require_relative 'info_builder'
require_relative 'servers_builder'
require_relative 'components_builder'
require_relative 'webhook_builder'

module GrapeSwagger
  module OpenAPI
    class SpecBuilderV3_1
      def self.build(options)
        raise ArgumentError, 'info is required' unless options[:info]

        spec = { openapi: '3.1.0' }

        # Build info object
        spec[:info] = InfoBuilder.build(options)

        # Build servers array if present
        servers = ServersBuilder.build(options)
        spec[:servers] = servers unless servers.empty?

        # Build paths (default to empty hash)
        spec[:paths] = options[:paths] || {}

        # Build components if present
        components = ComponentsBuilder.build(options)
        spec[:components] = components unless components.empty?

        # Include optional top-level fields
        spec[:security] = options[:security] if options[:security]
        spec[:tags] = options[:tags] if options[:tags]
        spec[:externalDocs] = options[:externalDocs] if options[:externalDocs]
        # Build webhooks if present
        if options[:webhooks]
          version = Version.new('3.1.0')
          webhooks = WebhookBuilder.build(options[:webhooks], version)
          spec[:webhooks] = webhooks if webhooks
        end

        spec
      end
    end
  end
end
