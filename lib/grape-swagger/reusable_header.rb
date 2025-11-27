# frozen_string_literal: true

module GrapeSwagger
  class ReusableHeader
    class << self
      def inherited(subclass)
        super
        # Defer registration to allow DSL to execute
        # Use :b_return to catch Class.new blocks, :end to catch class definitions
        TracePoint.new(:end, :b_return) do |tp|
          if tp.self == subclass
            GrapeSwagger::ComponentsRegistry.register_header(subclass)
            tp.disable
          end
        end.enable
      end

      # DSL Methods
      def component_name(val = nil)
        return @component_name if val.nil?

        @component_name = val
      end

      def description(val)
        @description = val
      end

      def schema(opts)
        @schema = opts
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
          description: @description,
          schema: @schema,
          required: @required,
          deprecated: @deprecated,
          example: @example
        }.compact
      end
    end
  end
end
