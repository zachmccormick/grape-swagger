# frozen_string_literal: true

module GrapeSwagger
  class ReusableParameter
    class << self
      def inherited(subclass)
        super
        # Defer registration to allow DSL to execute
        TracePoint.new(:end) do |tp|
          if tp.self == subclass
            # Skip auto-registration for anonymous classes (will be registered manually after const_set)
            begin
              GrapeSwagger::ComponentsRegistry.register_parameter(subclass)
            rescue ArgumentError => e
              # Silently skip if we can't determine the name yet
              # This happens with Class.new before const_set
            end
            tp.disable
          end
        end.enable
      end

      # DSL Methods
      def component_name(val = nil)
        return @component_name if val.nil?

        @component_name = val
      end

      def name(val = nil)
        return @param_name if val.nil?

        @param_name = val
      end

      def in_location(val)
        @in = val
      end

      def in_query
        in_location('query')
      end

      def in_path
        in_location('path')
      end

      def in_header
        in_location('header')
      end

      def in_cookie
        in_location('cookie')
      end

      def schema(opts)
        @schema = opts
      end

      def description(val)
        @description = val
      end

      def required(val)
        @required = val
      end

      def deprecated(val)
        @deprecated = val
      end

      def example(val)
        @example = val
      end

      def to_openapi
        {
          name: @param_name,
          in: @in,
          schema: @schema,
          description: @description,
          required: @required,
          deprecated: @deprecated,
          example: @example
        }.compact
      end
    end
  end
end
