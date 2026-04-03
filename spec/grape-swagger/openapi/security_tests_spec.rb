# frozen_string_literal: true

require 'spec_helper'

describe 'Security Tests' do
  let(:version_3_1) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }

  describe 'input sanitization' do
    it 'handles special characters in discriminator mapping keys' do
      config = {
        property_name: 'type',
        mapping: {
          'test<script>' => 'Test',
          "test'injection" => 'Test2'
        }
      }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      expect(result[:mapping]).to have_key('test<script>')
      expect(result[:mapping]).to have_key("test'injection")
    end

    it 'handles HTML-like content in discriminator property name' do
      config = {
        property_name: '<img onerror=alert(1)>',
        mapping: { 'a' => 'A' }
      }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      expect(result[:propertyName]).to eq('<img onerror=alert(1)>')
    end

    it 'handles unicode in cache keys' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new
      unicode_key = "user_\u{1F600}_emoji"

      result = cache.fetch(unicode_key) { { type: 'object' } }

      expect(result[:type]).to eq('object')
    end

    it 'handles unicode in discriminator mapping values' do
      config = {
        property_name: 'type',
        mapping: { "\u{1F600}" => "Schema\u{2603}" }
      }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      expect(result[:mapping]).to have_key("\u{1F600}")
    end

    it 'handles very long strings in cache keys' do
      long_string = 'a' * 10_000
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new

      result = cache.fetch(long_string) { { type: 'string' } }

      expect(result[:type]).to eq('string')
    end

    it 'handles very long strings in discriminator property names' do
      long_name = 'x' * 5_000
      config = { property_name: long_name }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      expect(result[:propertyName]).to eq(long_name)
    end

    it 'handles empty string as type mapper input' do
      result = GrapeSwagger::OpenAPI::TypeMapper.map('')

      expect(result[:type]).to eq('string')
    end

    it 'handles special characters in type mapper input' do
      result = GrapeSwagger::OpenAPI::TypeMapper.map('../../etc/passwd')

      expect(result[:type]).to eq('string')
    end

    it 'handles null bytes in type mapper input' do
      result = GrapeSwagger::OpenAPI::TypeMapper.map("string\x00injection")

      expect(result[:type]).to eq('string')
    end
  end

  describe 'URL validation in security configs' do
    it 'accepts valid HTTPS URLs in OAuth config' do
      config = {
        type: 'oauth2',
        flows: {
          authorizationCode: {
            authorization_url: 'https://auth.example.com/authorize',
            token_url: 'https://auth.example.com/token',
            scopes: {}
          }
        }
      }

      result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config)

      expect(result[:flows][:authorizationCode][:authorizationUrl]).to eq('https://auth.example.com/authorize')
    end

    it 'accepts valid OpenID Connect discovery URL' do
      config = {
        type: 'openIdConnect',
        openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
      }

      result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config)

      expect(result[:openIdConnectUrl]).to eq('https://auth.example.com/.well-known/openid-configuration')
    end

    it 'passes through URLs without scheme validation' do
      config = {
        type: 'oauth2',
        flows: {
          authorizationCode: {
            authorization_url: 'http://insecure.example.com/auth',
            token_url: 'http://insecure.example.com/token',
            scopes: {}
          }
        }
      }

      result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config)

      expect(result[:flows][:authorizationCode][:authorizationUrl]).to eq('http://insecure.example.com/auth')
    end
  end

  describe 'reference handling' do
    it 'normalizes local refs correctly' do
      config = {
        property_name: 'type',
        mapping: {
          'dog' => 'Dog',
          'cat' => '#/components/schemas/Cat'
        }
      }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      expect(result[:mapping]['dog']).to eq('#/components/schemas/Dog')
      expect(result[:mapping]['cat']).to eq('#/components/schemas/Cat')
    end

    it 'handles external refs' do
      config = {
        property_name: 'type',
        mapping: {
          'external' => 'https://example.com/schemas/External.yaml#/ExternalSchema'
        }
      }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      expect(result[:mapping]['external']).to include('https://example.com')
    end

    it 'handles http external refs' do
      config = {
        property_name: 'type',
        mapping: {
          'ext' => 'http://example.com/schemas/Ext'
        }
      }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      expect(result[:mapping]['ext']).to start_with('http://')
    end

    it 'handles path traversal attempts in refs by treating as plain names' do
      config = {
        property_name: 'type',
        mapping: {
          'traversal' => '../../secrets/Schema'
        }
      }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      # Non-http, non-# refs get normalized as component refs
      expect(result[:mapping]['traversal']).to eq('#/components/schemas/../../secrets/Schema')
    end

    it 'normalizes schema refs in polymorphic builders' do
      result = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_one_of(
        ['Dog', { '$ref' => '#/components/schemas/Cat' }],
        nil,
        version_3_1
      )

      expect(result[:oneOf][0]).to eq({ '$ref' => '#/components/schemas/Dog' })
      expect(result[:oneOf][1]).to eq({ '$ref' => '#/components/schemas/Cat' })
    end
  end

  describe 'cache security' do
    it 'isolates cache entries' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new

      cache.fetch('user1_data') { { secret: 'user1_secret' } }
      cache.fetch('user2_data') { { secret: 'user2_secret' } }

      user1_result = cache.fetch('user1_data') { { secret: 'wrong' } }
      user2_result = cache.fetch('user2_data') { { secret: 'wrong' } }

      expect(user1_result[:secret]).to eq('user1_secret')
      expect(user2_result[:secret]).to eq('user2_secret')
    end

    it 'clears all data on invalidate' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new

      cache.fetch('sensitive') { { data: 'secret' } }
      cache.invalidate

      expect(cache.size).to eq(0)
    end

    it 'selectively invalidates by key' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new

      cache.fetch('keep') { 'keep_value' }
      cache.fetch('remove') { 'remove_value' }
      cache.invalidate('remove')

      expect(cache.size).to eq(1)
      expect(cache.fetch('keep') { 'wrong' }).to eq('keep_value')
    end

    it 'prevents cache pollution through size limits' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new(max_size: 2)

      cache.fetch('key1') { 'value1' }
      cache.fetch('key2') { 'value2' }
      cache.fetch('key3') { 'value3' }

      expect(cache.size).to be <= 2
    end

    it 'returns cached value on subsequent fetch with same key' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new
      call_count = 0

      cache.fetch('key') { call_count += 1; 'result' }
      cache.fetch('key') { call_count += 1; 'different' }

      expect(call_count).to eq(1)
    end

    it 'tracks hit and miss statistics' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new

      cache.fetch('a') { 1 }
      cache.fetch('a') { 2 }
      cache.fetch('b') { 3 }

      stats = cache.stats
      expect(stats[:misses]).to eq(2)
      expect(stats[:hits]).to eq(1)
      expect(stats[:hit_rate]).to be > 0
    end
  end

  describe 'type coercion safety' do
    it 'handles symbol keys in discriminator config' do
      config = { property_name: 'type' }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      expect(result[:propertyName]).to eq('type')
    end

    it 'handles string keys in discriminator config' do
      config = { 'property_name' => 'type' }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      # Builder uses symbol keys, so string key lookup returns nil propertyName
      expect(result[:propertyName]).to be_nil
    end

    it 'handles mixed key types in mapping' do
      config = {
        property_name: 'type',
        mapping: {
          :symbol_key => 'Symbol',
          'string_key' => 'String'
        }
      }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config)

      expect(result[:mapping].keys.size).to eq(2)
    end

    it 'TypeMapper maps integer correctly' do
      result = GrapeSwagger::OpenAPI::TypeMapper.map('integer')

      expect(result[:type]).to eq('integer')
    end

    it 'handles frozen schemas in nullable handler' do
      schema = { type: 'string', nullable: true }.freeze

      # Should not modify the frozen original
      result = GrapeSwagger::OpenAPI::NullableTypeHandler.transform(schema, version_3_1)

      expect(result[:type]).to eq(%w[string null])
      expect(schema[:nullable]).to be true # original unchanged
    end

    it 'handles frozen schemas in binary encoder' do
      schema = { type: 'string', format: 'binary' }.freeze

      result = GrapeSwagger::OpenAPI::BinaryDataEncoder.encode(schema, version_3_1)

      expect(result[:contentEncoding]).to eq('base64')
      expect(schema[:format]).to eq('binary') # original unchanged
    end
  end

  describe 'resource limits' do
    it 'benchmark suite handles zero iterations gracefully' do
      expect do
        GrapeSwagger::OpenAPI::BenchmarkSuite.run_benchmark(iterations: 0, warmup: false) { 1 }
      end.not_to raise_error
    end

    it 'benchmark suite returns valid structure for zero iterations' do
      result = GrapeSwagger::OpenAPI::BenchmarkSuite.run_benchmark(iterations: 0, warmup: false) { 1 }

      expect(result[:generation_time]).to be_a(Hash)
      expect(result[:generation_time][:avg]).to eq(0.0)
      expect(result[:memory_usage]).to eq(0)
      expect(result[:object_allocations]).to eq(0)
    end

    it 'lazy component builder handles many registrations' do
      builder = GrapeSwagger::OpenAPI::LazyComponentBuilder.new(version_3_1)

      100.times do |i|
        builder.register("Component#{i}") { { type: 'object', id: i } }
      end

      expect(builder.pending_count).to eq(100)

      result = builder.resolve('Component50')
      expect(result[:id]).to eq(50)
    end

    it 'lazy component builder resolves without re-evaluating' do
      builder = GrapeSwagger::OpenAPI::LazyComponentBuilder.new(version_3_1)
      call_count = 0

      builder.register('Once') { call_count += 1; { type: 'object' } }

      builder.resolve('Once')
      builder.resolve('Once')

      expect(call_count).to eq(1)
    end

    it 'lazy component builder returns nil for unregistered components' do
      builder = GrapeSwagger::OpenAPI::LazyComponentBuilder.new(version_3_1)

      expect(builder.resolve('NonExistent')).to be_nil
    end

    it 'cache eviction removes oldest entries first' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new(max_size: 3)

      cache.fetch('first') { 'first_value' }
      cache.fetch('second') { 'second_value' }
      cache.fetch('third') { 'third_value' }
      cache.fetch('fourth') { 'fourth_value' }

      expect(cache.size).to be <= 3
      # The oldest entry should have been evicted
      result = cache.fetch('first') { 'recomputed' }
      expect(result).to eq('recomputed')
    end
  end

  describe 'error handling' do
    it 'ReferenceCache handles exception in block' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new

      expect do
        cache.fetch('error_key') { raise 'Simulated error' }
      end.to raise_error('Simulated error')

      # Cache should not have corrupted state
      result = cache.fetch('safe_key') { 'safe_value' }
      expect(result).to eq('safe_value')
    end

    it 'BenchmarkSuite handles exception during measurement' do
      expect do
        GrapeSwagger::OpenAPI::BenchmarkSuite.measure_object_allocations do
          raise 'Measurement error'
        end
      end.to raise_error('Measurement error')

      # GC should be re-enabled even after error
      expect(GC.enable).to be_falsey # Returns false if already enabled
    end

    it 'VersionSelector raises on unsupported version string' do
      expect do
        GrapeSwagger::OpenAPI::VersionSelector.validate_version('99.99.99')
      end.to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
    end

    it 'VersionSelector raises on nil version' do
      expect do
        GrapeSwagger::OpenAPI::VersionSelector.validate_version(nil)
      end.to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
    end

    it 'TypeMapper raises on empty type array' do
      expect do
        GrapeSwagger::OpenAPI::TypeMapper.map_with_type_array([])
      end.to raise_error(ArgumentError, 'Type array cannot be empty')
    end
  end

  describe 'thread safety' do
    it 'ReferenceCache is thread-safe for concurrent reads and writes' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new
      errors = []

      threads = 10.times.map do |i|
        Thread.new do
          50.times do |j|
            cache.fetch("thread_#{i}_key_#{j}") { "value_#{i}_#{j}" }
          end
        rescue StandardError => e
          errors << e
        end
      end

      threads.each(&:join)

      expect(errors).to be_empty
      expect(cache.size).to eq(500)
    end

    it 'ReferenceCache handles concurrent invalidation' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new
      errors = []

      # Pre-populate
      50.times { |i| cache.fetch("key_#{i}") { "value_#{i}" } }

      threads = []
      threads << Thread.new do
        25.times { |i| cache.invalidate("key_#{i}") }
      rescue StandardError => e
        errors << e
      end
      threads << Thread.new do
        50.times { |i| cache.fetch("new_key_#{i}") { "new_#{i}" } }
      rescue StandardError => e
        errors << e
      end

      threads.each(&:join)

      expect(errors).to be_empty
    end
  end
end
