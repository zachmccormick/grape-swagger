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
            refs << value['$ref'] if value['$ref']
            value.each_value { |v| extract_refs_from_value(v, refs) }
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

        detect_circular_references if options[:detect_circular]

        {
          valid: errors.empty?,
          errors: errors,
          warnings: warnings
        }
      end

      private

      def validate_reference(ref)
        warn_deprecated_style(ref)

        if external_reference?(ref)
          handle_external_reference(ref)
          return
        end

        validate_internal_reference(ref)
      end

      def warn_deprecated_style(ref)
        return unless spec['openapi']&.start_with?('3.') && ref.include?('#/definitions/')

        warnings << "Deprecated reference style found: #{ref}. " \
                    'Use #/components/schemas/ for OpenAPI 3.x'
      end

      def external_reference?(ref)
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

        return if @available_refs.include?(ref_path)

        context = find_reference_context(ref)
        errors << "Reference #{ref} not found in specification#{context}"
      end

      def find_reference_context(ref)
        context_parts = []
        find_ref_location(spec, ref, [], context_parts)

        return " (referenced from: #{context_parts.first})" if context_parts.any?

        ''
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
            break if results.any?
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
        add_schema_refs(refs)
        add_response_refs(refs)
        add_parameter_refs(refs)
        add_other_component_refs(refs)
        refs
      end

      def add_schema_refs(refs)
        spec['components']&.[]('schemas')&.each_key do |name|
          refs << "components/schemas/#{name}"
        end
        spec['definitions']&.each_key do |name|
          refs << "definitions/#{name}"
        end
      end

      def add_response_refs(refs)
        spec['components']&.[]('responses')&.each_key do |name|
          refs << "components/responses/#{name}"
        end
        spec['responses']&.each_key do |name|
          refs << "responses/#{name}"
        end
      end

      def add_parameter_refs(refs)
        spec['components']&.[]('parameters')&.each_key do |name|
          refs << "components/parameters/#{name}"
        end
        spec['parameters']&.each_key do |name|
          refs << "parameters/#{name}"
        end
      end

      def add_other_component_refs(refs)
        return unless spec['components']

        %w[examples requestBodies headers securitySchemes links callbacks].each do |component_type|
          spec['components'][component_type]&.each_key do |name|
            refs << "components/#{component_type}/#{name}"
          end
        end
      end

      def detect_circular_references
        return unless spec['components']&.[]('schemas') || spec['definitions']

        schemas = spec['components']&.[]('schemas') || spec['definitions'] || {}
        prefix = spec['components'] ? 'components/schemas' : 'definitions'

        schemas.each_key do |schema_name|
          path = ["#/#{prefix}/#{schema_name}"]
          is_circular = circular_reference?(schemas[schema_name], schema_name, path, prefix)

          is_self_ref = path.length == 2 && options[:allow_self_reference]

          next if is_circular && is_self_ref

          warnings << "Circular reference detected: #{path.join(' -> ')}" if is_circular
        end
      end

      def circular_reference?(schema, target_name, path, prefix, visited = Set.new)
        return false unless schema.is_a?(Hash)

        return check_ref_circularity(schema, target_name, path, prefix, visited) if schema['$ref']

        check_nested_circularity(schema, target_name, path, prefix, visited)
      end

      def check_ref_circularity(schema, target_name, path, prefix, visited)
        ref_name = schema['$ref'].split('/').last

        return true if ref_name == target_name
        return false if visited.include?(ref_name)

        visited = visited.dup
        visited.add(ref_name)

        schemas = spec['components']&.[]('schemas') || spec['definitions'] || {}
        referenced_schema = schemas[ref_name]

        if referenced_schema
          path.push("#/#{prefix}/#{ref_name}")
          return circular_reference?(referenced_schema, target_name, path, prefix, visited)
        end

        false
      end

      def check_nested_circularity(schema, target_name, path, prefix, visited)
        schema.each_value do |value|
          case value
          when Hash
            return true if circular_reference?(value, target_name, path, prefix, visited)
          when Array
            value.each do |item|
              return true if item.is_a?(Hash) && circular_reference?(item, target_name, path, prefix, visited)
            end
          end
        end

        false
      end
    end
  end
end
