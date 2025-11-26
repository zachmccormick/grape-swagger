# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # ReferenceCache provides thread-safe caching for schema reference resolution
    #
    # Used to avoid repeated lookups of the same schema references during
    # OpenAPI document generation, improving performance for large APIs.
    #
    # @example Basic usage
    #   cache = ReferenceCache.new
    #   schema = cache.fetch('User') { build_user_schema }
    #
    # @example With size limit
    #   cache = ReferenceCache.new(max_size: 100)
    #
    class ReferenceCache
      DEFAULT_MAX_SIZE = 1000

      def initialize(max_size: DEFAULT_MAX_SIZE)
        @cache = {}
        @max_size = max_size
        @mutex = Mutex.new
        @hits = 0
        @misses = 0
      end

      # Fetches a value from cache or computes it using the block
      #
      # @param key [String] The cache key
      # @yield Block to compute value on cache miss
      # @return [Object] The cached or computed value
      def fetch(key, &block)
        @mutex.synchronize do
          if @cache.key?(key)
            @hits += 1
            return @cache[key]
          end

          @misses += 1
          evict_if_full
          @cache[key] = block.call
        end
      end

      # Invalidates cache entries
      #
      # @param key [String, nil] Specific key to invalidate, or nil to clear all
      def invalidate(key = nil)
        @mutex.synchronize do
          if key
            @cache.delete(key)
          else
            @cache.clear
          end
        end
      end

      # Returns current cache size
      #
      # @return [Integer] Number of cached entries
      def size
        @mutex.synchronize { @cache.size }
      end

      # Returns cache statistics
      #
      # @return [Hash] Statistics including size, hits, and misses
      def stats
        @mutex.synchronize do
          {
            size: @cache.size,
            max_size: @max_size,
            hits: @hits,
            misses: @misses,
            hit_rate: calculate_hit_rate
          }
        end
      end

      private

      def evict_if_full
        return unless @cache.size >= @max_size

        # FIFO eviction - remove oldest inserted entries
        keys_to_remove = @cache.keys.first(@cache.size - @max_size + 1)
        keys_to_remove.each { |k| @cache.delete(k) }
      end

      def calculate_hit_rate
        total = @hits + @misses
        return 0.0 if total.zero?

        (@hits.to_f / total * 100).round(2)
      end
    end
  end
end
