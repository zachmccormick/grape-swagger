# Sprint 15: Performance Optimization
## Phase 5 - Production Ready

### Sprint Overview
**Duration**: 3 days
**Sprint Goal**: Optimize generation speed and memory usage to ensure OpenAPI 3.1.0 support has no performance regression.

### User Stories

#### Story 15.1: Performance Profiling
**As a** library maintainer
**I want to** profile the generation process
**So that** I can identify optimization targets

**Acceptance Criteria**:
- [ ] Profiling harness established
- [ ] Baseline metrics captured
- [ ] Hot spots identified
- [ ] Memory allocation tracked
- [ ] Comparison with Swagger 2.0

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Benchmark for 10 endpoint API
- Benchmark for 50 endpoint API
- Benchmark for 100 endpoint API
- Memory usage measurement
- Object allocation count
- Reference resolution timing
```

#### Story 15.2: Caching Implementation
**As a** developer
**I want** reference resolution to be cached
**So that** repeated lookups are fast

**Acceptance Criteria**:
- [ ] Schema reference cache
- [ ] Component resolution cache
- [ ] Cache invalidation strategy
- [ ] Thread-safe caching
- [ ] Configurable cache size

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Cache hit returns same object
- Cache miss triggers lookup
- Cache invalidation works
- Thread safety verification
- Cache size limits respected
- Performance improvement measured
```

#### Story 15.3: Lazy Loading
**As a** user with large APIs
**I want** components to load on-demand
**So that** initial generation is fast

**Acceptance Criteria**:
- [ ] Lazy schema resolution
- [ ] On-demand component building
- [ ] Deferred reference expansion
- [ ] Memory-efficient for large APIs
- [ ] No behavior change for consumers

**TDD Tests Required**:
```ruby
# RED Phase tests:
- Unused components not generated
- Referenced components generated on access
- Deep references resolved correctly
- Circular references handled
- Memory footprint reduced
```

#### Story 15.4: String Building Optimization
**As a** performance-conscious user
**I want** efficient JSON/YAML generation
**So that** output is fast

**Acceptance Criteria**:
- [ ] Efficient string concatenation
- [ ] Buffer reuse where possible
- [ ] Minimal intermediate objects
- [ ] Streaming output option
- [ ] Memory-efficient for large specs

**TDD Tests Required**:
```ruby
# RED Phase tests:
- String building faster than naive approach
- Memory allocation reduced
- Large spec generation stable
- Output format unchanged
- Encoding handled correctly
```

### Technical Implementation

#### Performance Benchmark Suite
```ruby
module GrapeSwagger
  module Benchmark
    class Suite
      SIZES = [10, 50, 100, 250].freeze
      ITERATIONS = 10

      def self.run
        results = {}

        SIZES.each do |size|
          api = generate_test_api(size)

          results[size] = {
            generation_time: measure_generation(api),
            memory_usage: measure_memory(api),
            object_allocations: measure_allocations(api)
          }
        end

        results
      end

      private

      def self.measure_generation(api)
        times = ITERATIONS.times.map do
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          api.generate_swagger
          Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        end

        {
          min: times.min,
          max: times.max,
          avg: times.sum / times.size,
          median: times.sort[times.size / 2]
        }
      end

      def self.measure_memory(api)
        GC.start
        before = memory_usage
        api.generate_swagger
        after = memory_usage

        after - before
      end

      def self.memory_usage
        `ps -o rss= -p #{Process.pid}`.to_i * 1024
      end
    end
  end
end
```

#### Reference Cache
```ruby
module GrapeSwagger
  module OpenAPI
    class ReferenceCache
      DEFAULT_MAX_SIZE = 1000

      def initialize(max_size: DEFAULT_MAX_SIZE)
        @cache = {}
        @max_size = max_size
        @mutex = Mutex.new
      end

      def fetch(key, &block)
        @mutex.synchronize do
          return @cache[key] if @cache.key?(key)

          evict_if_full
          @cache[key] = block.call
        end
      end

      def invalidate(key = nil)
        @mutex.synchronize do
          key ? @cache.delete(key) : @cache.clear
        end
      end

      def stats
        @mutex.synchronize do
          {
            size: @cache.size,
            max_size: @max_size,
            hit_rate: calculate_hit_rate
          }
        end
      end

      private

      def evict_if_full
        return unless @cache.size >= @max_size

        # LRU eviction - remove oldest entries
        keys_to_remove = @cache.keys.first(@cache.size - @max_size + 1)
        keys_to_remove.each { |k| @cache.delete(k) }
      end
    end
  end
end
```

#### Lazy Component Builder
```ruby
module GrapeSwagger
  module OpenAPI
    class LazyComponentBuilder
      def initialize(version)
        @version = version
        @pending = {}
        @resolved = {}
      end

      def register(name, &builder)
        @pending[name] = builder
      end

      def resolve(name)
        return @resolved[name] if @resolved.key?(name)

        builder = @pending.delete(name)
        return nil unless builder

        @resolved[name] = builder.call
      end

      def resolve_all
        @pending.each_key { |name| resolve(name) }
        @resolved
      end

      def resolved_components
        @resolved.dup
      end
    end
  end
end
```

### Configuration API
```ruby
add_swagger_documentation(
  openapi_version: '3.1.0',
  performance: {
    cache_enabled: true,
    cache_max_size: 1000,
    lazy_loading: true,
    profiling: Rails.env.development?
  }
)
```

### Performance Targets

| Metric | Swagger 2.0 Baseline | OpenAPI 3.1.0 Target | Acceptable |
|--------|---------------------|----------------------|------------|
| 10 endpoints | 25ms | 25ms | 30ms |
| 50 endpoints | 125ms | 125ms | 150ms |
| 100 endpoints | 250ms | 250ms | 300ms |
| Memory (100 ep) | 50MB | 50MB | 60MB |
| Object allocs | 10,000 | 10,000 | 12,000 |

### Definition of Done
- [ ] TDD: All RED tests written
- [ ] TDD: All tests GREEN
- [ ] TDD: Code refactored
- [ ] Benchmark suite created
- [ ] Caching implemented
- [ ] Lazy loading working
- [ ] Performance targets met
- [ ] Code review passed

### Sprint Metrics
- **Story Points**: 13
- **Estimated Hours**: 24
- **Risk Level**: Medium
- **Dependencies**: Phases 1-4 complete

---

**Next Sprint**: Sprint 16 will focus on documentation and migration guides.
