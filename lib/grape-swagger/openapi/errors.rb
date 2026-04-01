# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    module Errors
      class UnsupportedVersionError < StandardError
        def initialize(version = nil, supported = [])
          message = if version.nil?
                      "Unsupported OpenAPI version. Supported versions: #{supported.join(', ')}"
                    else
                      "Unsupported OpenAPI version: #{version}. Supported versions: #{supported.join(', ')}"
                    end
          super(message)
        end
      end
    end
  end
end
