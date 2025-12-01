# frozen_string_literal: true

module GrapeSwagger
  class ReusableResponse
    class << self
      def inherited(subclass)
        super
        # Defer registration to allow DSL to execute
        # Use :b_return to catch Class.new blocks, :end to catch class definitions
        TracePoint.new(:end, :b_return) do |tp|
          if tp.self == subclass
            # Skip auto-registration for anonymous classes (will be registered manually after const_set)
            begin
              GrapeSwagger::ComponentsRegistry.register_response(subclass)
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

      def description(val)
        @description = val
      end

      def content(media_type, opts = {})
        @content ||= {}
        @content[media_type] = opts
      end

      def json_schema(entity_or_schema)
        content 'application/json', schema: entity_or_schema
      end

      def headers(&block)
        @headers_block = block
      end

      def to_openapi
        result = { description: @description }
        result[:content] = @content if @content && !@content.empty?
        result[:headers] = build_headers if @headers_block
        result.compact
      end

      private

      def build_headers
        # Future: evaluate headers block
        nil
      end
    end
  end
end
