# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class VersionSelector
      include VersionConstants

      def self.detect_version(options)
        return options[:openapi_version] if options[:openapi_version]
        return options[:swagger_version] if options[:swagger_version]

        SWAGGER_2_0
      end

      def self.validate_version(version)
        return if SUPPORTED_VERSIONS.include?(version)

        raise Errors::UnsupportedVersionError.new(version, SUPPORTED_VERSIONS)
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
