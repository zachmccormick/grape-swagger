# PR 22: Performance Utilities

## Overview

Standalone performance utility classes for the grape-swagger OpenAPI 3.x implementation. These utilities support caching, lazy evaluation, and benchmarking but are not yet integrated into the generation pipeline.

## Components

### ReferenceCache

Thread-safe LRU cache for schema reference resolution. Avoids repeated lookups of the same schema references during OpenAPI document generation.

**Features:**
- Thread-safe via Mutex synchronization
- Configurable max size (default: 1000)
- FIFO eviction when cache is full
- Hit/miss statistics with hit rate calculation
- Selective or full invalidation

**Usage:**
```ruby
cache = GrapeSwagger::OpenAPI::ReferenceCache.new(max_size: 100)
schema = cache.fetch('User') { build_user_schema }
stats = cache.stats  # { size: 1, max_size: 100, hits: 0, misses: 1, hit_rate: 0.0 }
```

### LazyComponentBuilder

On-demand component building with deferred evaluation. Components are registered with builder blocks but not built until resolved.

**Features:**
- Deferred block evaluation (blocks not called until resolve)
- Circular reference protection via $ref indirection
- Automatic pending-to-resolved lifecycle management
- Memory-efficient (pending block removed after resolution)
- Component dependency support (resolve within resolve)

**Usage:**
```ruby
builder = GrapeSwagger::OpenAPI::LazyComponentBuilder.new(version)
builder.register('User') { { type: 'object', properties: { name: { type: 'string' } } } }
# Block not called yet...
schema = builder.resolve('User')  # Now the block is called
all = builder.resolve_all          # Resolve everything remaining
```

### BenchmarkSuite

Performance measurement utilities for timing, memory, and object allocation analysis.

**Features:**
- High-resolution timing via `Process::CLOCK_MONOTONIC`
- Memory usage measurement via process RSS
- Object allocation counting (T_OBJECT, T_HASH, T_ARRAY, T_STRING)
- Statistical aggregation (min, max, avg, median)
- Warmup iteration support
- Result comparison with regression detection (20% threshold)
- Human-readable result formatting

**Usage:**
```ruby
result = GrapeSwagger::OpenAPI::BenchmarkSuite.run_benchmark(iterations: 10) do
  api.swagger_doc
end
puts GrapeSwagger::OpenAPI::BenchmarkSuite.format_results(result)

comparison = GrapeSwagger::OpenAPI::BenchmarkSuite.compare(baseline, current)
puts "Regression detected!" if comparison[:regression]
```

## File Manifest

| File | Purpose |
|------|---------|
| `lib/grape-swagger/openapi/reference_cache.rb` | Thread-safe LRU cache |
| `lib/grape-swagger/openapi/lazy_component_builder.rb` | Lazy component building |
| `lib/grape-swagger/openapi/benchmark_suite.rb` | Performance measurement |
| `spec/grape-swagger/openapi/reference_cache_spec.rb` | ReferenceCache specs |
| `spec/grape-swagger/openapi/lazy_component_builder_spec.rb` | LazyComponentBuilder specs |
| `spec/grape-swagger/openapi/benchmark_suite_spec.rb` | BenchmarkSuite specs |

## Integration Status

These are standalone utilities with no pipeline integration. They will be wired into the generation pipeline in a future PR.
