# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # BenchmarkSuite provides performance measurement utilities
    #
    # Used to measure and compare generation performance of OpenAPI specs,
    # helping ensure no performance regression between versions.
    #
    # @example Basic usage
    #   result = BenchmarkSuite.run_benchmark(iterations: 10) do
    #     api.swagger_doc
    #   end
    #   puts BenchmarkSuite.format_results(result)
    #
    class BenchmarkSuite
      # Default regression threshold (20% slower is a regression)
      REGRESSION_THRESHOLD = 0.2

      # Measures execution time of a block
      #
      # @yield Block to measure
      # @return [Float] Time in seconds
      def self.measure_generation_time(&block)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        block.call
        Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      end

      # Measures memory usage during block execution
      #
      # @yield Block to measure
      # @return [Integer] Memory change in bytes
      def self.measure_memory_usage(&block)
        GC.start
        before = current_memory
        block.call
        GC.start
        after = current_memory
        [after - before, 0].max
      end

      # Counts object allocations during block execution
      #
      # @yield Block to measure
      # @return [Integer] Number of objects allocated
      def self.measure_object_allocations(&block)
        GC.start
        GC.disable

        before = ObjectSpace.count_objects[:T_OBJECT] + ObjectSpace.count_objects[:T_HASH] +
                 ObjectSpace.count_objects[:T_ARRAY] + ObjectSpace.count_objects[:T_STRING]

        block.call

        after = ObjectSpace.count_objects[:T_OBJECT] + ObjectSpace.count_objects[:T_HASH] +
                ObjectSpace.count_objects[:T_ARRAY] + ObjectSpace.count_objects[:T_STRING]

        GC.enable
        [after - before, 0].max
      end

      # Runs a complete benchmark
      #
      # @param iterations [Integer] Number of iterations to run
      # @param warmup [Boolean] Whether to run a warmup iteration
      # @yield Block to benchmark
      # @return [Hash] Benchmark results
      def self.run_benchmark(iterations: 10, warmup: true, &block)
        # Warm up (doesn't count toward iterations)
        block.call if warmup

        # Collect timing samples
        times = iterations.times.map { measure_generation_time(&block) }

        # Measure memory and allocations separately (on fresh runs)
        memory = measure_memory_usage(&block)
        allocations = measure_object_allocations(&block)

        {
          generation_time: {
            min: times.min,
            max: times.max,
            avg: times.sum / times.size,
            median: calculate_median(times)
          },
          memory_usage: memory,
          object_allocations: allocations
        }
      end

      # Compares two benchmark results
      #
      # @param baseline [Hash] Baseline benchmark results
      # @param current [Hash] Current benchmark results
      # @return [Hash] Comparison with change percentages
      def self.compare(baseline, current)
        baseline_time = baseline[:generation_time][:avg].to_f
        current_time = current[:generation_time][:avg].to_f
        baseline_memory = [baseline[:memory_usage].to_f, 1].max
        current_memory = current[:memory_usage].to_f

        time_change = ((current_time - baseline_time) / baseline_time * 100).round(1)
        memory_change = ((current_memory - baseline_memory) / baseline_memory * 100).round(1)

        {
          time_change_percent: time_change,
          memory_change_percent: memory_change,
          regression: time_change > (REGRESSION_THRESHOLD * 100) ||
            memory_change > (REGRESSION_THRESHOLD * 100)
        }
      end

      # Formats benchmark results as a readable string
      #
      # @param result [Hash] Benchmark results
      # @return [String] Formatted results
      def self.format_results(result)
        time = result[:generation_time]
        <<~OUTPUT
          Generation Time:
            Min: #{format_time(time[:min])}
            Max: #{format_time(time[:max])}
            Avg: #{format_time(time[:avg])}
            Median: #{format_time(time[:median])}

          Memory Usage: #{format_bytes(result[:memory_usage])}

          Object Allocations: #{result[:object_allocations]}
        OUTPUT
      end

      class << self
        private

        def current_memory
          `ps -o rss= -p #{Process.pid}`.to_i * 1024
        rescue StandardError
          0
        end

        def calculate_median(array)
          sorted = array.sort
          mid = sorted.size / 2
          sorted.size.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
        end

        def format_time(seconds)
          if seconds < 0.001
            format('%.3f ms', seconds * 1000)
          elsif seconds < 1
            format('%.2f ms', seconds * 1000)
          else
            format('%.2f s', seconds)
          end
        end

        def format_bytes(bytes)
          if bytes < 1024
            "#{bytes} B"
          elsif bytes < 1024 * 1024
            format('%.2f KB', bytes / 1024.0)
          else
            format('%.2f MB', bytes / (1024.0 * 1024))
          end
        end
      end
    end
  end
end
