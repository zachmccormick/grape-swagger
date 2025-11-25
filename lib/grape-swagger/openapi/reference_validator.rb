# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class ReferenceValidator
      class << self
        # Validates all references in an OpenAPI specification
        #
        # @param spec [Hash] The OpenAPI specification
        # @param options [Hash] Validation options
        # @option options [Boolean] :detect_circular (true) Whether to detect circular references
        # @option options [Boolean] :strict (false) Whether to reject external references
        # @option options [Boolean] :allow_self_reference (true) Whether to allow self-references
        # @return [Hash] Validation result with :valid, :errors, and :warnings keys
        def validate(spec, options = {})
          options = default_options.merge(options)

          validator = new(spec, options)
          validator.validate
        end

        # Extracts all unique $ref values from a specification
        #
        # @param spec [Hash] The OpenAPI specification
        # @return [Array<String>] Array of unique reference paths
        def extract_references(spec)
          refs = []
          extract_refs_from_value(spec, refs)
          refs.uniq
        end

        private

        def default_options
          {
            detect_circular: true,
            strict: false,
            allow_self_reference: true
          }
        end

        def extract_refs_from_value(value, refs)
          case value
          when Hash
            if value['$ref']
              refs << value['$ref']
            end
            value.each { |_k, v| extract_refs_from_value(v, refs) }
          when Array
            value.each { |v| extract_refs_from_value(v, refs) }
          end
        end
      end

      attr_reader :spec, :options, :errors, :warnings

      def initialize(spec, options)
        @spec = spec
        @options = options
        @errors = []
        @warnings = []
        @available_refs = build_available_refs
      end

      def validate
        references = self.class.extract_references(spec)

        references.each do |ref|
          validate_reference(ref)
        end

        if options[:detect_circular]
          detect_circular_references
        end

        {
          valid: errors.empty?,
          errors: errors,
          warnings: warnings
        }
      end

      private

      def validate_reference(ref)
        # Check for deprecated Swagger 2.0 style in OpenAPI 3.1.0 spec
        if spec['openapi']&.start_with?('3.') && ref.include?('#/definitions/')
          warnings << "Deprecated reference style found: #{ref}. " \
                     "Use #/components/schemas/ for OpenAPI 3.x"
        end

        # Handle external references
        if external_reference?(ref)
          handle_external_reference(ref)
          return
        end

        # Validate internal reference exists
        validate_internal_reference(ref)
      end

      def external_reference?(ref)
        # External if it starts with a URL scheme or contains a file path before #
        ref.match?(%r{^https?://}) || (ref.include?('#') && !ref.start_with?('#'))
      end

      def handle_external_reference(ref)
        if options[:strict]
          errors << "External reference not allowed in strict mode: #{ref}"
        else
          warnings << "External reference found (not validated): #{ref}"
        end
      end

      def validate_internal_reference(ref)
        return unless ref.start_with?('#/')

        ref_path = ref.sub('#/', '')

        unless @available_refs.include?(ref_path)
          # Find which schema is referencing this missing ref
          context = find_reference_context(ref)
          errors << "Reference #{ref} not found in specification#{context}"
        end
      end

      def find_reference_context(ref)
        # Find where this reference is used to provide helpful error message
        context_parts = []

        find_ref_location(spec, ref, [], context_parts)

        if context_parts.any?
          " (referenced from: #{context_parts.first})"
        else
          ""
        end
      end

      def find_ref_location(value, target_ref, path, results)
        case value
        when Hash
          if value['$ref'] == target_ref
            results << path.join('.')
            return
          end
          value.each do |k, v|
            find_ref_location(v, target_ref, path + [k], results)
            break if results.any? # Found it, stop searching
          end
        when Array
          value.each_with_index do |v, i|
            find_ref_location(v, target_ref, path + ["[#{i}]"], results)
            break if results.any?
          end
        end
      end

      def build_available_refs
        refs = Set.new

        # Add all schemas
        if spec['components']&.[]('schemas')
          spec['components']['schemas'].each_key do |name|
            refs << "components/schemas/#{name}"
          end
        end

        # Support legacy definitions (Swagger 2.0)
        if spec['definitions']
          spec['definitions'].each_key do |name|
            refs << "definitions/#{name}"
          end
        end

        # Add all responses
        if spec['components']&.[]('responses')
          spec['components']['responses'].each_key do |name|
            refs << "components/responses/#{name}"
          end
        end

        # Support legacy responses
        if spec['responses']
          spec['responses'].each_key do |name|
            refs << "responses/#{name}"
          end
        end

        # Add all parameters
        if spec['components']&.[]('parameters')
          spec['components']['parameters'].each_key do |name|
            refs << "components/parameters/#{name}"
          end
        end

        # Support legacy parameters
        if spec['parameters']
          spec['parameters'].each_key do |name|
            refs << "parameters/#{name}"
          end
        end

        # Add other component types
        if spec['components']
          %w[examples requestBodies headers securitySchemes links callbacks].each do |component_type|
            next unless spec['components'][component_type]

            spec['components'][component_type].each_key do |name|
              refs << "components/#{component_type}/#{name}"
            end
          end
        end

        refs
      end

      def detect_circular_references
        return unless spec['components']&.[]('schemas') || spec['definitions']

        schemas = spec['components']&.[]('schemas') || spec['definitions'] || {}
        prefix = spec['components'] ? 'components/schemas' : 'definitions'

        schemas.each_key do |schema_name|
          path = ["#/#{prefix}/#{schema_name}"]
          if has_circular_reference?(schemas[schema_name], schema_name, path, prefix)
            # Check if it's a self-reference
            if path.length == 2 && options[:allow_self_reference]
              # Self-reference is allowed, don't warn
              next
            end

            warnings << "Circular reference detected: #{path.join(' -> ')}"
          end
        end
      end

      def has_circular_reference?(schema, target_name, path, prefix, visited = Set.new)
        return false unless schema.is_a?(Hash)

        # Check direct reference
        if schema['$ref']
          ref_name = schema['$ref'].split('/').last

          # Found circular reference
          if ref_name == target_name
            return true
          end

          # Avoid infinite recursion
          return false if visited.include?(ref_name)

          visited = visited.dup
          visited.add(ref_name)

          # Get the referenced schema
          schemas = spec['components']&.[]('schemas') || spec['definitions'] || {}
          referenced_schema = schemas[ref_name]

          if referenced_schema
            path.push("#/#{prefix}/#{ref_name}")
            return has_circular_reference?(referenced_schema, target_name, path, prefix, visited)
          end
        end

        # Check nested structures
        schema.each_value do |value|
          case value
          when Hash
            return true if has_circular_reference?(value, target_name, path, prefix, visited)
          when Array
            value.each do |item|
              return true if item.is_a?(Hash) && has_circular_reference?(item, target_name, path, prefix, visited)
            end
          end
        end

        false
      end
    end
  end
end
