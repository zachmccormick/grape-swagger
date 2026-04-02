# frozen_string_literal: true

module GrapeSwagger
  class ReusableExample
    class << self
      def inherited(subclass)
        super
        # Defer registration to allow DSL to execute
        # Use :b_return to catch Class.new blocks, :end to catch class definitions
        TracePoint.new(:end, :b_return) do |tp|
          if tp.self == subclass
            # Skip auto-registration for anonymous classes (will be registered manually after const_set)
            begin
              GrapeSwagger::ComponentsRegistry.register_example(subclass)
            rescue ArgumentError
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

      def summary(val)
        @summary = val
      end

      def description(val)
        @description = val
      end

      def value(val)
        @value = val
      end

      def external_value(val)
        @external_value = val
      end

      def to_openapi
        result = {
          summary: @summary,
          description: @description
        }

        # value and externalValue are mutually exclusive
        if @external_value
          result[:externalValue] = @external_value
        elsif @value
          result[:value] = @value
        end

        result.compact
      end
    end
  end
end
