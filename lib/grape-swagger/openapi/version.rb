# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class Version
      attr_reader :version_string, :options

      def initialize(version_string, options = {})
        @version_string = version_string
        @options = options
      end

      def swagger_2_0?
        version_string == VersionConstants::SWAGGER_2_0
      end

      def openapi_3_1_0?
        version_string == VersionConstants::OPENAPI_3_1_0
      end
    end
  end
end
