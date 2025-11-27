# frozen_string_literal: true

module GrapeSwagger
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
        parameters[name] = klass
      end

      def register_response(klass)
        name = component_name_for(klass)
        responses[name] = klass
      end

      def register_header(klass)
        name = component_name_for(klass)
        headers[name] = klass
      end

      def component_name_for(klass)
        klass.component_name || klass.name&.split('::')&.last ||
          raise(ArgumentError, "Cannot determine component name for #{klass}")
      end

      def reset!
        @parameters = {}
        @responses = {}
        @headers = {}
      end
    end
  end
end
