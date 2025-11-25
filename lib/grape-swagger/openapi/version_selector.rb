# frozen_string_literal: true

require_relative 'version_constants'
require_relative 'version'
require_relative 'errors'

module GrapeSwagger
  module OpenAPI
    class VersionSelector
      include VersionConstants

      def self.detect_version(options)
        # Prioritize openapi_version over swagger_version
        return options[:openapi_version] if options[:openapi_version]

        # Fall back to swagger_version for backward compatibility
        return options[:swagger_version] if options[:swagger_version]

        # Default to Swagger 2.0
        SWAGGER_2_0
      end

      def self.validate_version(version)
        raise Errors::UnsupportedVersionError.new(version, SUPPORTED_VERSIONS) unless SUPPORTED_VERSIONS.include?(version)
      end

      def self.supported_versions
        SUPPORTED_VERSIONS
      end

      def self.build_spec(options)
        version = detect_version(options)
        validate_version(version)
        Version.new(version, options)
      end
    end
  end
end
