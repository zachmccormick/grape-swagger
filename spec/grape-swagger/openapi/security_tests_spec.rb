# frozen_string_literal: true

require 'spec_helper'

describe 'Security Tests' do
  let(:version_3_1) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }

  describe 'input sanitization' do
    it 'handles special characters in schema names' do
      config = {
        property_name: 'type',
        mapping: {
          'test<script>' => 'Test',
          "test'injection" => 'Test2'
        }
      }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config, version_3_1)

      expect(result[:mapping]).to have_key('test<script>')
      expect(result[:mapping]).to have_key("test'injection")
    end

    it 'handles unicode in descriptions' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new
      unicode_key = "user_\u{1F600}_emoji"

      result = cache.fetch(unicode_key) { { type: 'object' } }

      expect(result[:type]).to eq('object')
    end

    it 'handles very long strings' do
      long_string = 'a' * 10_000
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new

      result = cache.fetch(long_string) { { type: 'string' } }

      expect(result[:type]).to eq('string')
    end
  end

  describe 'URL validation' do
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

      result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

      expect(result[:flows][:authorizationCode][:authorizationUrl]).to eq('https://auth.example.com/authorize')
    end

    it 'accepts valid OpenID Connect discovery URL' do
      config = {
        type: 'openIdConnect',
        openid_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
      }

      result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

      expect(result[:openIdConnectUrl]).to eq('https://auth.example.com/.well-known/openid-configuration')
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

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config, version_3_1)

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

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config, version_3_1)

      expect(result[:mapping]['external']).to include('https://example.com')
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

    it 'prevents cache pollution through size limits' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new(max_size: 2)

      # rubocop:disable Style/RedundantFetchBlock -- ReferenceCache#fetch requires block to compute value
      cache.fetch('key1') { 'value1' }
      cache.fetch('key2') { 'value2' }
      cache.fetch('key3') { 'value3' }
      # rubocop:enable Style/RedundantFetchBlock

      expect(cache.size).to be <= 2
    end
  end

  describe 'type coercion safety' do
    it 'handles symbol keys in config' do
      config = { property_name: 'type' }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config, version_3_1)

      expect(result[:propertyName]).to eq('type')
    end

    it 'handles string keys in config' do
      config = { 'property_name' => 'type' }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config, version_3_1)

      # Builder uses symbol keys, so string key lookup would fail
      # This verifies the builder handles its expected input format
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

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config, version_3_1)

      expect(result[:mapping].keys.size).to eq(2)
    end
  end

  describe 'resource limits' do
    it 'benchmark suite handles zero iterations gracefully' do
      # This should not cause infinite loops or crashes
      expect do
        GrapeSwagger::OpenAPI::BenchmarkSuite.run_benchmark(iterations: 0, warmup: false) { 1 }
      end.not_to raise_error
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
  end

  describe 'error handling' do
    it 'ReferenceCache handles exception in block' do
      cache = GrapeSwagger::OpenAPI::ReferenceCache.new

      expect do
        cache.fetch('error_key') { raise 'Simulated error' }
      end.to raise_error('Simulated error')

      # Cache should not have corrupted state
      # rubocop:disable Style/RedundantFetchBlock -- ReferenceCache#fetch requires block
      result = cache.fetch('safe_key') { 'safe_value' }
      # rubocop:enable Style/RedundantFetchBlock
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
  end

  describe 'thread safety' do
    it 'ReferenceCache is thread-safe for reads and writes' do
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
  end
end
