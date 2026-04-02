# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # ConditionalSchemaBuilder handles if/then/else conditional schemas for OpenAPI 3.1.0
    #
    # OpenAPI 3.1.0 supports JSON Schema 2020-12 conditional keywords:
    # - if: condition schema
    # - then: schema to apply if condition is true
    # - else: schema to apply if condition is false
    #
    # @example Simple if/then
    #   schema = {
    #     type: 'object',
    #     if: { properties: { type: { const: 'A' } } },
    #     then: { properties: { prop_a: { type: 'string' } } }
    #   }
    #   ConditionalSchemaBuilder.build(schema, version)
    #
    # @example if/then/else
    #   schema = {
    #     if: { properties: { payment: { const: 'card' } } },
    #     then: { properties: { card_number: { type: 'string' } } },
    #     else: { properties: { account: { type: 'string' } } }
    #   }
    class ConditionalSchemaBuilder
      # Builds conditional schemas for OpenAPI 3.1.0
      #
      # @param schema [Hash] The schema to process
      # @param version [GrapeSwagger::OpenAPI::Version] The version object
      # @return [Hash] Processed schema
      def self.build(schema, version)
        return schema unless schema.is_a?(Hash)

        # For Swagger 2.0, strip conditional keywords (not supported)
        return strip_conditionals(schema) unless version.openapi_3_1_0?

        # For OpenAPI 3.1.0, preserve conditionals
        return schema unless has_conditionals?(schema)

        # Build the result with conditionals intact
        result = schema.dup

        # Process nested conditionals in allOf, oneOf, anyOf
        process_nested_conditionals(result, version)

        result
      end

      private_class_method def self.has_conditionals?(schema)
        schema.key?(:if) || schema.key?(:then) || schema.key?(:else) ||
          has_nested_conditionals?(schema)
      end

      private_class_method def self.has_nested_conditionals?(schema)
        # Check if allOf, oneOf, anyOf contain conditionals
        %i[allOf oneOf anyOf].any? do |key|
          next false unless schema[key].is_a?(Array)

          schema[key].any? { |s| s.is_a?(Hash) && (s.key?(:if) || s.key?(:then) || s.key?(:else)) }
        end
      end

      private_class_method def self.strip_conditionals(schema)
        result = schema.dup
        result.delete(:if)
        result.delete(:then)
        result.delete(:else)

        # Also strip from nested structures
        %i[allOf oneOf anyOf].each do |key|
          next unless result[key].is_a?(Array)

          result[key] = result[key].map { |s| s.is_a?(Hash) ? strip_conditionals(s) : s }
        end

        result
      end

      private_class_method def self.process_nested_conditionals(schema, version)
        # Process conditionals in composition keywords
        %i[allOf oneOf anyOf].each do |key|
          next unless schema[key].is_a?(Array)

          schema[key] = schema[key].map { |s| build(s, version) }
        end
      end
    end
  end
end
