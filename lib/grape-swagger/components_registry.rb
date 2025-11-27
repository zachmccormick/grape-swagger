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

      def component_name_for(klass)
        klass.component_name || klass.name&.split('::')&.last ||
          raise(ArgumentError, "Cannot determine component name for #{klass}")
      end

      def to_openapi
        result = {}

        unless parameters.empty?
          result[:parameters] = parameters.transform_values(&:to_openapi)
        end

        unless responses.empty?
          result[:responses] = responses.transform_values(&:to_openapi)
        end

        unless headers.empty?
          result[:headers] = headers.transform_values(&:to_openapi)
        end

        result
      end

      def reset!
        @parameters = {}
        @responses = {}
        @headers = {}
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
