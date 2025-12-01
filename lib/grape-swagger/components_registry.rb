# frozen_string_literal: true

module GrapeSwagger
  class ComponentNotFoundError < StandardError; end

  class ComponentsRegistry
    class << self
      def parameters
        @parameters ||= {}
      end

      def responses
        @responses ||= {}
      end

      def headers
        @headers ||= {}
      end

      def examples
        @examples ||= {}
      end

      def request_bodies
        @request_bodies ||= {}
      end

      def register_parameter(klass)
        name = component_name_for(klass)
        warn_collision(:parameters, name, klass)
        parameters[name] = klass
      end

      def register_response(klass)
        name = component_name_for(klass)
        warn_collision(:responses, name, klass)
        responses[name] = klass
      end

      def register_header(klass)
        name = component_name_for(klass)
        warn_collision(:headers, name, klass)
        headers[name] = klass
      end

      def register_example(klass)
        name = component_name_for(klass)
        warn_collision(:examples, name, klass)
        examples[name] = klass
      end

      def register_request_body(klass)
        name = component_name_for(klass)
        warn_collision(:request_bodies, name, klass)
        request_bodies[name] = klass
      end

      def find_parameter!(name)
        parameters[name.to_s] || raise(
          ComponentNotFoundError,
          "Parameter component '#{name}' not found. Available: #{parameters.keys.join(', ')}"
        )
      end

      def find_response!(name)
        responses[name.to_s] || raise(
          ComponentNotFoundError,
          "Response component '#{name}' not found. Available: #{responses.keys.join(', ')}"
        )
      end

      def find_header!(name)
        headers[name.to_s] || raise(
          ComponentNotFoundError,
          "Header component '#{name}' not found. Available: #{headers.keys.join(', ')}"
        )
      end

      def find_example!(name)
        examples[name.to_s] || raise(
          ComponentNotFoundError,
          "Example component '#{name}' not found. Available: #{examples.keys.join(', ')}"
        )
      end

      def find_request_body!(name)
        request_bodies[name.to_s] || raise(
          ComponentNotFoundError,
          "RequestBody component '#{name}' not found. Available: #{request_bodies.keys.join(', ')}"
        )
      end

      def component_name_for(klass)
        return klass.component_name if klass.component_name

        # Try to_s first (works for classes defined with const_set)
        # For named classes, to_s returns the class name
        # For anonymous classes, to_s returns something like "#<Class:0x...>"
        stringified = klass.to_s
        return stringified.split('::').last unless stringified.start_with?('#<')

        # Fall back to .name for test mocks that define custom name methods
        # Note: Some DSL classes override .name, so this is a fallback
        class_name = klass.name
        return class_name.split('::').last if class_name && !class_name.start_with?('#<')

        raise ArgumentError, "Cannot determine component name for #{klass}"
      end

      def to_openapi
        result = {}

        result[:parameters] = parameters.transform_values(&:to_openapi) unless parameters.empty?

        result[:responses] = responses.transform_values(&:to_openapi) unless responses.empty?

        result[:headers] = headers.transform_values(&:to_openapi) unless headers.empty?

        result[:examples] = examples.transform_values(&:to_openapi) unless examples.empty?

        result[:requestBodies] = request_bodies.transform_values(&:to_openapi) unless request_bodies.empty?

        result
      end

      def reset!
        @parameters = {}
        @responses = {}
        @headers = {}
        @examples = {}
        @request_bodies = {}
      end

      private

      def warn_collision(type, name, klass)
        registry = send(type)
        return unless registry[name] && registry[name] != klass

        warn "[grape-swagger] Component name collision: #{name} already registered " \
             "by #{registry[name].name}, now being overwritten by #{klass.name}. " \
             "Use `component_name 'UniqueNameHere'` to resolve."
      end
    end
  end
end
