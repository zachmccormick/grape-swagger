# frozen_string_literal: true

require_relative 'encoding_builder'

module GrapeSwagger
  module OpenAPI
    class ContentNegotiator
      # Media type priority for content negotiation
      # Lower number = higher priority
      MEDIA_TYPE_PRIORITY = {
        'application/json' => 1,
        'application/xml' => 2,
        'multipart/form-data' => 3,
        'application/x-www-form-urlencoded' => 4
      }.freeze

      class << self
        # Negotiate media types for request and response
        #
        # @param consumes [Array<String>, nil] Request media types
        # @param produces [Array<String>, nil] Response media types
        # @return [Hash] Hash with :request_types and :response_types
        def negotiate(consumes, produces)
          {
            request_types: prioritize(consumes),
            response_types: prioritize(produces)
          }
        end

        # Build content object for multiple media types
        #
        # @param types [Array<String>] Media type strings
        # @param schema [Hash, Hash<String, Hash>] Schema object or hash of schemas per type
        # @param examples [Hash, nil] Examples hash (can be media-type-specific or generic)
        # @param version [GrapeSwagger::OpenAPI::Version] OpenAPI version
        # @return [Hash] Content object with media type keys
        def build_content(types, schema, examples, version)
          return {} if types.nil? || types.empty?

          types.each_with_object({}) do |media_type, content|
            # Get schema for this media type
            type_schema = if schema.is_a?(Hash) && schema.key?(media_type)
                            # Schema is a hash with per-type schemas
                            schema[media_type]
                          elsif schema.is_a?(Hash) && schema.key?(media_type.to_sym)
                            # Try symbol key
                            schema[media_type.to_sym]
                          else
                            # Use the schema as-is for all types
                            schema
                          end

            content[media_type] = build_media_type_object(type_schema, examples, media_type, version)
          end
        end

        # Add encoding configuration to multipart content
        #
        # @param content [Hash] Content object
        # @param encoding_config [Hash, nil] Encoding configuration per field
        # @param version [GrapeSwagger::OpenAPI::Version] OpenAPI version
        # @return [Hash] Content object with encoding added
        def add_encoding(content, encoding_config, version)
          return content if encoding_config.nil? || encoding_config.empty?

          content.each do |media_type, media_type_obj|
            next unless multipart_type?(media_type)

            # Build encoding object for all fields
            encoding = EncodingBuilder.build_for_fields(encoding_config, version)
            media_type_obj[:encoding] = encoding if encoding
          end

          content
        end

        private

        # Prioritize media types based on priority list
        #
        # @param types [Array<String>, nil] Media types
        # @return [Array<String>] Prioritized media types
        def prioritize(types)
          return [] if types.nil? || types.empty?

          # Separate known and unknown types
          known = []
          unknown = []

          types.each do |type|
            if MEDIA_TYPE_PRIORITY.key?(type)
              known << type
            else
              unknown << type
            end
          end

          # Sort known types by priority, preserve unknown order
          known.sort_by { |type| MEDIA_TYPE_PRIORITY[type] } + unknown
        end

        # Build a media type object
        #
        # @param schema [Hash] Schema object
        # @param examples [Hash, nil] Examples data
        # @param media_type [String] Media type string
        # @param version [GrapeSwagger::OpenAPI::Version] OpenAPI version
        # @return [Hash] Media type object with schema and examples
        def build_media_type_object(schema, examples, media_type, version)
          result = {
            schema: schema
          }

          # Add examples if present
          if examples
            examples_data = extract_examples(examples, media_type)
            result[:example] = examples_data[:example] if examples_data[:example]
            result[:examples] = examples_data[:examples] if examples_data[:examples]
          end

          result
        end

        # Extract examples for a specific media type
        #
        # @param examples [Hash] Examples hash
        # @param media_type [String] Media type string
        # @return [Hash] Hash with :example or :examples
        def extract_examples(examples, media_type)
          result = {}

          # Check for single example
          if examples.key?(:example)
            result[:example] = examples[:example]
            return result
          end

          # Check for named examples
          if examples.key?(:examples)
            result[:examples] = examples[:examples]
            return result
          end

          # Check for media-type-specific examples
          media_examples = examples[media_type] || examples[media_type.to_sym]
          return result unless media_examples

          # Check if it's a named examples map
          if media_examples.is_a?(Hash) && has_named_examples?(media_examples)
            result[:examples] = media_examples
          else
            # Single example value
            result[:example] = media_examples
          end

          result
        end

        # Check if examples hash contains named examples
        #
        # @param examples [Hash] Examples hash
        # @return [Boolean] true if named examples
        def has_named_examples?(examples)
          examples.values.any? do |v|
            v.is_a?(Hash) && (v.key?(:summary) || v.key?(:value) || v.key?('summary') || v.key?('value'))
          end
        end

        # Check if media type is multipart
        #
        # @param media_type [String] Media type string
        # @return [Boolean] true if multipart
        def multipart_type?(media_type)
          media_type == 'multipart/form-data'
        end
      end
    end
  end
end
