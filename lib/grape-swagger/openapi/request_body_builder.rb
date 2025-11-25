# frozen_string_literal: true

require_relative 'content_negotiator'

module GrapeSwagger
  module OpenAPI
    class RequestBodyBuilder
      # HTTP methods that support request bodies
      BODY_METHODS = %w[POST PUT PATCH].freeze

      class << self
        # Builds a RequestBody object for OpenAPI 3.1.0
        #
        # @param params [Array<Hash>] Array of parameter definitions
        # @param method [String] HTTP method (GET, POST, PUT, PATCH, DELETE, etc.)
        # @param consumes [Array<String>] Array of media type strings
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] RequestBody object or nil
        def build(params, method, consumes, version)
          # Only build requestBody for OpenAPI 3.1.0
          return nil unless version.openapi_3_1_0?

          # Only build requestBody for methods that support request bodies
          return nil unless body_allowed?(method)

          # Extract body parameters
          body_params = extract_body_params(params)
          return nil if body_params.empty?

          # Validate consumes
          return nil if consumes.nil? || consumes.empty?

          # Build the requestBody object
          {
            required: determine_required(body_params),
            content: build_content(body_params, consumes, version),
            description: build_description(body_params)
          }.compact
        end

        private

        # Check if the HTTP method allows a request body
        #
        # @param method [String] HTTP method
        # @return [Boolean] true if method allows request body
        def body_allowed?(method)
          BODY_METHODS.include?(method.to_s.upcase)
        end

        # Extract parameters with in: 'body'
        #
        # @param params [Array<Hash>] All parameters
        # @return [Array<Hash>] Body parameters only
        def extract_body_params(params)
          params.select { |p| p[:in] == 'body' }
        end

        # Determine if the request body is required
        #
        # @param body_params [Array<Hash>] Body parameters
        # @return [Boolean] true if any body parameter is required
        def determine_required(body_params)
          body_params.any? { |p| p[:required] == true }
        end

        # Build the content object with media types
        #
        # @param body_params [Array<Hash>] Body parameters
        # @param consumes [Array<String>] Media types
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Content object with media type keys
        def build_content(body_params, consumes, version)
          # Prioritize media types using ContentNegotiator
          negotiated = ContentNegotiator.negotiate(consumes, [])
          prioritized_types = negotiated[:request_types]

          # Build schema for each media type
          prioritized_types.each_with_object({}) do |media_type, content|
            content[media_type] = build_media_type_object(body_params, media_type, version)
          end
        end

        # Build a media type object (schema + examples)
        #
        # @param body_params [Array<Hash>] Body parameters
        # @param media_type [String] Media type string
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Media type object
        def build_media_type_object(body_params, media_type, version)
          result = {
            schema: build_schema(body_params, media_type, version)
          }

          # Add examples if present
          examples_data = extract_examples(body_params)
          result[:example] = examples_data[:example] if examples_data[:example]
          result[:examples] = examples_data[:examples] if examples_data[:examples]

          result
        end

        # Build the schema for the request body
        #
        # @param body_params [Array<Hash>] Body parameters
        # @param media_type [String] Media type string
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Schema object
        def build_schema(body_params, media_type, version)
          # If there's a single body parameter with a $ref, use it directly
          if body_params.length == 1 && body_params.first[:$ref]
            ref = body_params.first[:$ref]
            translated_ref = SchemaResolver.translate_ref(ref, version)
            return { '$ref': translated_ref }
          end

          # If there's a single body parameter with type and properties, use it
          if body_params.length == 1 && body_params.first[:type]
            param = body_params.first
            schema = build_schema_from_param(param)
            return SchemaResolver.translate_schema(schema, version)
          end

          # For multiple body parameters or form data, merge properties
          if form_media_type?(media_type)
            build_form_schema(body_params, version)
          else
            build_merged_schema(body_params, version)
          end
        end

        # Build schema from a single parameter
        #
        # @param param [Hash] Parameter definition
        # @return [Hash] Schema object
        def build_schema_from_param(param)
          schema = { type: param[:type] }
          schema[:properties] = param[:properties] if param[:properties]
          schema[:items] = param[:items] if param[:items]
          schema[:format] = param[:format] if param[:format]
          schema[:$ref] = param[:$ref] if param[:$ref]
          schema
        end

        # Build schema by merging properties from multiple body parameters
        #
        # @param body_params [Array<Hash>] Body parameters
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Merged schema object
        def build_merged_schema(body_params, version)
          properties = {}

          body_params.each do |param|
            if param[:properties]
              properties.merge!(param[:properties])
            elsif param[:name] && param[:type]
              # Create a property for this parameter
              properties[param[:name].to_sym] = {
                type: param[:type]
              }
              properties[param[:name].to_sym][:format] = param[:format] if param[:format]
            end
          end

          schema = {
            type: 'object',
            properties: properties
          }

          SchemaResolver.translate_schema(schema, version)
        end

        # Build schema for form data (multipart or URL encoded)
        #
        # @param body_params [Array<Hash>] Body parameters
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Form schema object
        def build_form_schema(body_params, version)
          properties = {}

          body_params.each do |param|
            if param[:properties]
              properties.merge!(param[:properties])
            elsif param[:name]
              properties[param[:name].to_sym] = {
                type: param[:type] || 'string'
              }
              properties[param[:name].to_sym][:format] = param[:format] if param[:format]
            end
          end

          schema = {
            type: 'object',
            properties: properties
          }

          SchemaResolver.translate_schema(schema, version)
        end

        # Check if media type is a form type
        #
        # @param media_type [String] Media type string
        # @return [Boolean] true if form type
        def form_media_type?(media_type)
          ['multipart/form-data', 'application/x-www-form-urlencoded'].include?(media_type)
        end

        # Extract examples from body parameters
        #
        # @param body_params [Array<Hash>] Body parameters
        # @return [Hash] Hash with :example or :examples keys
        def extract_examples(body_params)
          result = {}

          # Look for examples in the first body parameter
          first_param = body_params.first
          return result unless first_param

          # Single example
          result[:example] = first_param[:example] if first_param[:example]

          # Named examples
          result[:examples] = first_param[:examples] if first_param[:examples]

          result
        end

        # Build description for the request body
        #
        # @param body_params [Array<Hash>] Body parameters
        # @return [String, nil] Description string
        def build_description(body_params)
          # Use the description from the first body parameter
          body_params.first&.[](:description)
        end
      end
    end
  end
end
