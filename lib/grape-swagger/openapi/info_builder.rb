# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class InfoBuilder
      DEFAULT_VERSION = '0.0.1'

      def self.build(options)
        raise ArgumentError, 'info is required' unless options[:info]

        info = options[:info].dup

        # Ensure version is present
        info[:version] ||= DEFAULT_VERSION

        # Add x-base-path extension if base_path is present
        info[:'x-base-path'] = options[:base_path] if options[:base_path]

        info
      end
    end
  end
end
