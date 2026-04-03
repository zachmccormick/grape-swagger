# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::ReferenceCache do
  let(:cache) { described_class.new }

  describe '#fetch' do
    it 'returns cached value on hit' do
      call_count = 0
      block = -> { call_count += 1; 'value' }

      first_result = cache.fetch('key', &block)
      second_result = cache.fetch('key', &block)

      expect(first_result).to eq('value')
      expect(second_result).to eq('value')
      expect(call_count).to eq(1)
    end

    it 'calls block on cache miss' do
      result = cache.fetch('missing') { 'computed' }

      expect(result).to eq('computed')
    end

    it 'stores different values for different keys' do
      cache.fetch('key1') { 'value1' }
      cache.fetch('key2') { 'value2' }

      expect(cache.fetch('key1') { 'wrong' }).to eq('value1')
      expect(cache.fetch('key2') { 'wrong' }).to eq('value2')
    end

    it 'handles nil values correctly' do
      call_count = 0
      block = -> { call_count += 1; nil }

      first_result = cache.fetch('nil_key', &block)
      second_result = cache.fetch('nil_key', &block)

      expect(first_result).to be_nil
      expect(second_result).to be_nil
      expect(call_count).to eq(1)
    end
  end

  describe '#invalidate' do
    it 'removes specific key when provided' do
      cache.fetch('key1') { 'value1' }
      cache.fetch('key2') { 'value2' }

      cache.invalidate('key1')

      expect(cache.fetch('key1') { 'new_value1' }).to eq('new_value1')
      expect(cache.fetch('key2') { 'wrong' }).to eq('value2')
    end

    it 'clears all entries when no key provided' do
      cache.fetch('key1') { 'value1' }
      cache.fetch('key2') { 'value2' }

      cache.invalidate

      expect(cache.fetch('key1') { 'new_value1' }).to eq('new_value1')
      expect(cache.fetch('key2') { 'new_value2' }).to eq('new_value2')
    end
  end

  describe 'cache size limits' do
    let(:cache) { described_class.new(max_size: 3) }

    it 'respects max_size configuration' do
      cache.fetch('key1') { 'value1' }
      cache.fetch('key2') { 'value2' }
      cache.fetch('key3') { 'value3' }
      cache.fetch('key4') { 'value4' }

      expect(cache.size).to be <= 3
    end

    it 'evicts oldest entries when full' do
      cache.fetch('key1') { 'value1' }
      cache.fetch('key2') { 'value2' }
      cache.fetch('key3') { 'value3' }
      cache.fetch('key4') { 'value4' }

      # key1 should be evicted (oldest)
      expect(cache.fetch('key1') { 'new_value1' }).to eq('new_value1')
      expect(cache.fetch('key4') { 'wrong' }).to eq('value4')
    end
  end

  describe 'thread safety' do
    it 'handles concurrent access without errors' do
      threads = 10.times.map do |i|
        Thread.new do
          100.times do |j|
            cache.fetch("key_#{i}_#{j}") { "value_#{i}_#{j}" }
          end
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end

    it 'maintains data integrity under concurrent access' do
      results = []
      mutex = Mutex.new

      threads = 5.times.map do
        Thread.new do
          value = cache.fetch('shared_key') { 'shared_value' }
          mutex.synchronize { results << value }
        end
      end

      threads.each(&:join)

      expect(results.uniq).to eq(['shared_value'])
    end
  end

  describe '#size' do
    it 'returns current cache size' do
      expect(cache.size).to eq(0)

      cache.fetch('key1') { 'value1' }
      expect(cache.size).to eq(1)

      cache.fetch('key2') { 'value2' }
      expect(cache.size).to eq(2)
    end
  end

  describe '#stats' do
    it 'returns cache statistics' do
      cache.fetch('key1') { 'value1' }
      cache.fetch('key1') { 'wrong' } # hit
      cache.fetch('key2') { 'value2' } # miss

      stats = cache.stats

      expect(stats[:size]).to eq(2)
      expect(stats).to have_key(:hits)
      expect(stats).to have_key(:misses)
    end
  end
end
