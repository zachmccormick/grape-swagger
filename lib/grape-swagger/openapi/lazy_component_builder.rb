# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # LazyComponentBuilder provides on-demand component building
    #
    # Components are registered with builder blocks but not built until
    # they are actually needed (resolved). This reduces memory usage and
    # improves initial generation time for large APIs where not all
    # components may be referenced.
    #
    # @example Basic usage
    #   builder = LazyComponentBuilder.new(version)
    #   builder.register('User') { { type: 'object', properties: { name: { type: 'string' } } } }
    #   # Block not called yet...
    #   schema = builder.resolve('User')  # Now the block is called
    #
    class LazyComponentBuilder
      def initialize(version)
        @version = version
        @pending = {}
        @resolved = {}
      end

      # Registers a component with a lazy builder block
      #
      # @param name [String] The component name
      # @yield Block that builds the component when resolved
      # @return [void]
      def register(name, &builder)
        @pending[name] = builder
      end

      # Resolves a component by name, building it if necessary
      #
      # @param name [String] The component name
      # @return [Hash, nil] The resolved component or nil if not found
      def resolve(name)
        return @resolved[name] if @resolved.key?(name)

        builder = @pending.delete(name)
        return nil unless builder

        @resolved[name] = builder.call
      end

      # Resolves all pending components
      #
      # @return [Hash] All resolved components
      def resolve_all
        @pending.each_key { |name| resolve(name) }
        @resolved.dup
      end

      # Returns a copy of all resolved components
      #
      # @return [Hash] Copy of resolved components
      def resolved_components
        @resolved.dup
      end

      # Returns the number of pending (unresolved) components
      #
      # @return [Integer]
      def pending_count
        @pending.size
      end

      # Returns the number of resolved components
      #
      # @return [Integer]
      def resolved_count
        @resolved.size
      end
    end
  end
end
