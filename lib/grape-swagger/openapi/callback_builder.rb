# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class CallbackBuilder
      class << self
        # Builds callbacks object for OpenAPI 3.1.0
        #
        # @param callback_definitions [Hash] Hash of callback definitions
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] Callbacks object or nil
        def build(callback_definitions, version)
          # Only OpenAPI 3.1.0 supports callbacks
          return nil unless version.openapi_3_1_0?

          # Return nil if callback_definitions is blank
          return nil if callback_definitions.nil? || callback_definitions.empty?

          # Build each callback
          callback_definitions.each_with_object({}) do |(name, config), callbacks|
            callbacks[name.to_s] = build_callback(config, version)
          end
        end

        private

        # Build a single callback definition
        #
        # @param config [Hash] Callback configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Callback path object with runtime expression as key
        def build_callback(config, version)
          # Get the URL expression (can contain runtime expressions)
          url_expression = config[:url]

          # Build the operation under the URL expression
          {
            url_expression => build_operation(config, version)
          }
        end

        # Build callback operation (similar to path operation)
        #
        # @param config [Hash] Callback configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Operation object with HTTP method as key
        def build_operation(config, version)
          # Determine HTTP method (default to POST)
          method = config[:method] || :post

          # Build the operation
          {
            method => build_operation_object(config, version)
          }
        end

        # Build the operation object (summary, description, requestBody, responses)
        #
        # @param config [Hash] Callback configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Operation details
        def build_operation_object(config, version)
          operation = {}

          # Add summary and description
          operation[:summary] = config[:summary] if config[:summary]
          operation[:description] = config[:description] if config[:description]

          # Add requestBody
          request_body = build_request_body(config[:request], version)
          operation[:requestBody] = request_body if request_body

          # Add responses
          responses = build_responses(config[:responses], version)
          operation[:responses] = responses if responses

          operation
        end

        # Build requestBody for callback
        #
        # @param request_config [Hash] Request configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] RequestBody object or nil
        def build_request_body(request_config, _version)
          return nil unless request_config

          request_body = {
            required: request_config[:required] != false, # Default to true
            content: build_content(request_config)
          }

          # Add description if present
          request_body[:description] = request_config[:description] if request_config[:description]

          request_body
        end

        # Build content object for requestBody
        #
        # @param request_config [Hash] Request configuration
        # @return [Hash] Content object with media types
        def build_content(request_config)
          media_type = request_config[:content_type] || 'application/json'

          media_type_object = {
            schema: build_schema(request_config[:schema])
          }
          media_type_object[:examples] = request_config[:examples] if request_config[:examples]

          { media_type => media_type_object }
        end

        # Build schema object
        #
        # @param schema_config [Hash] Schema configuration
        # @return [Hash] Schema object
        def build_schema(schema_config)
          return {} unless schema_config

          # If it's a $ref, return it with proper key format
          return { '$ref' => schema_config['$ref'] } if schema_config['$ref']

          # Otherwise, build the schema directly
          schema = {}
          schema[:type] = schema_config[:type] if schema_config[:type]
          schema[:properties] = schema_config[:properties] if schema_config[:properties]
          schema[:items] = translate_items(schema_config[:items]) if schema_config[:items]
          schema[:format] = schema_config[:format] if schema_config[:format]

          schema
        end

        # Translate items for array schemas
        #
        # @param items [Hash] Items configuration
        # @return [Hash] Translated items
        def translate_items(items)
          return items unless items

          # If items has a $ref, return it with proper key format
          return { '$ref' => items['$ref'] } if items['$ref']

          items
        end

        # Build responses object
        #
        # @param responses_config [Hash] Responses configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] Responses object or nil
        def build_responses(responses_config, _version)
          return nil unless responses_config

          responses_config.each_with_object({}) do |(code, response_config), responses|
            responses[code.to_s] = build_response(response_config)
          end
        end

        # Build a single response object
        #
        # @param response_config [Hash] Response configuration
        # @return [Hash] Response object
        def build_response(response_config)
          response = {
            description: response_config[:description] || ''
          }

          # Add content if schema is present
          if response_config[:schema]
            media_type = response_config[:content_type] || 'application/json'
            response[:content] = {
              media_type => {
                schema: build_schema(response_config[:schema])
              }
            }
          end

          response
        end
      end
    end
  end
end
