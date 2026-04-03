# frozen_string_literal: true

require_relative 'schema_resolver'

module GrapeSwagger
  module OpenAPI
    class WebhookBuilder
      class << self
        # Builds webhooks object for OpenAPI 3.1.0
        #
        # @param webhook_definitions [Hash] Hash of webhook definitions
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] Webhooks object or nil
        def build(webhook_definitions, version)
          # Return nil if webhook_definitions is blank
          return nil if webhook_definitions.nil? || webhook_definitions.empty?

          # Build each webhook
          webhook_definitions.each_with_object({}) do |(name, config), webhooks|
            webhooks[name.to_s] = build_webhook(config, version)
          end
        end

        private

        # Build a single webhook definition
        #
        # @param config [Hash] Webhook configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Webhook operation object
        def build_webhook(config, version)
          # Determine HTTP method (default to POST)
          method = config[:method] || :post

          # Build the operation
          {
            method => build_operation(config, version)
          }
        end

        # Build webhook operation (similar to path operation)
        #
        # @param config [Hash] Webhook configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Operation object
        def build_operation(config, version)
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

        # Build requestBody for webhook
        #
        # @param request_config [Hash] Request configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] RequestBody object or nil
        def build_request_body(request_config, version)
          return nil unless request_config

          request_body = {
            required: request_config[:required] != false, # Default to true
            content: build_content(request_config, version)
          }

          # Add description if present
          request_body[:description] = request_config[:description] if request_config[:description]

          request_body
        end

        # Build content object for requestBody
        #
        # @param request_config [Hash] Request configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Content object with media types
        def build_content(request_config, version)
          media_type = request_config[:content_type] || 'application/json'

          media_type_object = {
            schema: build_schema(request_config[:schema], version)
          }
          media_type_object[:examples] = request_config[:examples] if request_config[:examples]

          { media_type => media_type_object }
        end

        # Build schema object
        #
        # @param schema_config [Hash] Schema configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Schema object
        def build_schema(schema_config, version)
          return {} unless schema_config

          # If it's a $ref, return it with proper key format
          if schema_config['$ref']
            return { '$ref' => schema_config['$ref'] }
          end

          # Otherwise, build the schema directly
          schema = {}
          schema[:type] = schema_config[:type] if schema_config[:type]
          schema[:properties] = schema_config[:properties] if schema_config[:properties]
          schema[:items] = translate_items(schema_config[:items], version) if schema_config[:items]

          schema
        end

        # Translate items for array schemas
        #
        # @param items [Hash] Items configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Translated items
        def translate_items(items, version)
          return items unless items

          # If items has a $ref, return it with proper key format
          if items['$ref']
            return { '$ref' => items['$ref'] }
          end

          items
        end

        # Build responses object
        #
        # @param responses_config [Hash] Responses configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash, nil] Responses object or nil
        def build_responses(responses_config, version)
          return nil unless responses_config

          responses_config.each_with_object({}) do |(code, response_config), responses|
            responses[code.to_s] = build_response(response_config, version)
          end
        end

        # Build a single response object
        #
        # @param response_config [Hash] Response configuration
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Response object
        def build_response(response_config, version)
          response = {
            description: response_config[:description] || ''
          }

          # Add content if schema is present
          if response_config[:schema]
            media_type = response_config[:content_type] || 'application/json'
            response[:content] = {
              media_type => {
                schema: build_schema(response_config[:schema], version)
              }
            }
          end

          response
        end
      end
    end
  end
end
