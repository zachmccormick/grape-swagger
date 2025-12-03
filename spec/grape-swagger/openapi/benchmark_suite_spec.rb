# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::BenchmarkSuite do
  describe '.measure_generation_time' do
    it 'measures time for block execution' do
      result = described_class.measure_generation_time { sleep(0.01) }

      expect(result).to be >= 0.01
      expect(result).to be < 0.1
    end

    it 'returns time in seconds' do
      result = described_class.measure_generation_time { 1 + 1 }

      expect(result).to be_a(Float)
      expect(result).to be >= 0
    end
  end

  describe '.measure_memory_usage' do
    it 'measures memory for block execution' do
      result = described_class.measure_memory_usage { Array.new(1000) { 'x' * 100 } }

      expect(result).to be_a(Integer)
      expect(result).to be >= 0
    end

    it 'returns memory in bytes' do
      # Create some objects to measure
      result = described_class.measure_memory_usage { { key: 'value' } }

      expect(result).to be_a(Integer)
    end
  end

  describe '.measure_object_allocations' do
    it 'counts object allocations during block' do
      result = described_class.measure_object_allocations { Array.new(10) { {} } }

      expect(result).to be_a(Integer)
      expect(result).to be >= 10
    end

    it 'returns zero for no allocations' do
      x = 1
      result = described_class.measure_object_allocations { x + 1 }

      expect(result).to be_a(Integer)
      expect(result).to be >= 0
    end
  end

  describe '.run_benchmark' do
    it 'returns complete benchmark results' do
      result = described_class.run_benchmark(iterations: 3) { Array.new(100) }

      expect(result).to have_key(:generation_time)
      expect(result).to have_key(:memory_usage)
      expect(result).to have_key(:object_allocations)
    end

    it 'generation_time includes min, max, avg, median' do
      result = described_class.run_benchmark(iterations: 5) { 1 + 1 }

      expect(result[:generation_time]).to have_key(:min)
      expect(result[:generation_time]).to have_key(:max)
      expect(result[:generation_time]).to have_key(:avg)
      expect(result[:generation_time]).to have_key(:median)
    end

    it 'runs the block specified number of times plus warmup and measurements' do
      call_count = 0
      # iterations + warmup + memory measurement + allocation measurement = iterations + 3
      described_class.run_benchmark(iterations: 7) { call_count += 1 }

      expect(call_count).to eq(7 + 3) # 7 iterations + 1 warmup + 1 memory + 1 allocation
    end
  end

  describe '.compare' do
    it 'compares two benchmark results' do
      baseline = { generation_time: { avg: 100 }, memory_usage: 1000 }
      current = { generation_time: { avg: 80 }, memory_usage: 900 }

      comparison = described_class.compare(baseline, current)

      expect(comparison[:time_change_percent]).to eq(-20.0)
      expect(comparison[:memory_change_percent]).to eq(-10.0)
    end

    it 'indicates regression when current is worse' do
      baseline = { generation_time: { avg: 100 }, memory_usage: 1000 }
      current = { generation_time: { avg: 150 }, memory_usage: 1200 }

      comparison = described_class.compare(baseline, current)

      expect(comparison[:regression]).to be true
    end

    it 'indicates no regression when current is same or better' do
      baseline = { generation_time: { avg: 100 }, memory_usage: 1000 }
      current = { generation_time: { avg: 100 }, memory_usage: 1000 }

      comparison = described_class.compare(baseline, current)

      expect(comparison[:regression]).to be false
    end
  end

  describe '.format_results' do
    it 'formats results as readable string' do
      result = {
        generation_time: { min: 0.01, max: 0.02, avg: 0.015, median: 0.015 },
        memory_usage: 1024,
        object_allocations: 100
      }

      formatted = described_class.format_results(result)

      expect(formatted).to be_a(String)
      expect(formatted).to include('Generation Time')
      expect(formatted).to include('Memory Usage')
      expect(formatted).to include('Object Allocations')
    end
  end
end
