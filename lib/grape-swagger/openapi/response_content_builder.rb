# frozen_string_literal: true

require_relative 'schema_resolver'
require_relative 'content_negotiator'

module GrapeSwagger
  module OpenAPI
    class ResponseContentBuilder
      class << self
        # Builds a Response object for OpenAPI 3.1.0
        #
        # @param response [Hash] Response definition with description, schema, headers, examples
        # @param produces [Array<String>] Array of media type strings
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Response object with content wrapper for OpenAPI 3.1.0 or original for Swagger 2.0
        def build(response, produces, version)
          # Return original response for Swagger 2.0
          return response unless version.openapi_3_1_0?

          # Build the response object for OpenAPI 3.1.0
          result = {
            description: response[:description]
          }.compact

          # Add content object if schema is present
          content = build_content(response, produces, version)
          result[:content] = content if content

          # Add headers at response level (not inside content)
          result[:headers] = response[:headers] if response[:headers]

          result
        end

        private

        # Build the content object with media types
        #
        # @param response [Hash] Response definition
        # @param produces [Array<String>] Media types
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] Content object with media type keys or nil
        def build_content(response, produces, version)
          # Return nil if no schema
          return nil unless response[:schema]

          # Return nil if produces is nil or empty
          return nil if produces.nil? || produces.empty?

          # Prioritize media types using ContentNegotiator
          negotiated = ContentNegotiator.negotiate([], produces)
          prioritized_types = negotiated[:response_types]

          prioritized_types.each_with_object({}) do |media_type, content|
            content[media_type] = build_media_type_object(response, media_type, version)
          end
        end

        # Build a media type object (schema + examples)
        #
        # @param response [Hash] Response definition
        # @param media_type [String] Media type string
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Media type object
        def build_media_type_object(response, media_type, version)
          result = {
            schema: translate_schema(response[:schema], version)
          }

          # Add examples if present
          examples_data = extract_examples(response, media_type)
          result[:example] = examples_data[:example] if examples_data[:example]
          result[:examples] = examples_data[:examples] if examples_data[:examples]

          result
        end

        # Translate schema using SchemaResolver
        #
        # @param schema [Hash] Schema object
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Translated schema
        def translate_schema(schema, version)
          SchemaResolver.translate_schema(schema, version)
        end

        # Extract examples from response definition
        #
        # @param response [Hash] Response definition
        # @param media_type [String] Media type string
        # @return [Hash] Hash with :example or :examples keys
        def extract_examples(response, media_type)
          result = {}

          return result unless response[:examples]

          # Get examples for this specific media type
          # Try both string and symbol keys
          media_examples = response[:examples][media_type] || response[:examples][media_type.to_sym]
          return result unless media_examples

          # Check if it's a named examples map (has keys with summary/value structure)
          if media_examples.is_a?(Hash) && has_named_examples?(media_examples)
            result[:examples] = media_examples
          else
            # Single example value
            result[:example] = media_examples
          end

          result
        end

        # Check if examples hash contains named examples with summary/value structure
        #
        # @param examples [Hash] Examples hash
        # @return [Boolean] true if named examples
        def has_named_examples?(examples)
          # If any value is a hash with :summary or :value keys, it's named examples
          examples.values.any? { |v| v.is_a?(Hash) && (v.key?(:summary) || v.key?(:value) || v.key?('summary') || v.key?('value')) }
        end
      end
    end
  end
end
