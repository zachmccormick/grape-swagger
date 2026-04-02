# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class ServersBuilder
      DEFAULT_SCHEME = 'https'

      def self.build(options)
        # Prefer explicit servers array
        return options[:servers] if options[:servers]

        # Build from legacy host/basePath/schemes
        build_from_legacy(options)
      end

      def self.build_from_legacy(options)
        host = options[:host]
        base_path = options[:base_path]
        schemes = options[:schemes] || []

        # If no host, basePath, or schemes, return empty array
        return [] if host.nil? && base_path.nil? && schemes.empty?

        # Default to https if no schemes provided but host or base_path exists
        schemes = [DEFAULT_SCHEME] if schemes.empty? && (host || base_path)

        schemes.map do |scheme|
          build_server_url(scheme, host, base_path)
        end
      end

      def self.build_server_url(scheme, host, base_path)
        url_parts = []

        url_parts << "#{scheme}://#{host}" if host

        if base_path
          if host
            # Append base_path to host URL
            url_parts = ["#{url_parts[0]}#{base_path}"]
          else
            # Just base_path, no scheme or host
            url_parts << base_path
          end
        end

        { url: url_parts.join }
      end
    end
  end
end
