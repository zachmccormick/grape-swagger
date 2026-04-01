# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::Version do
  describe '#initialize' do
    it 'stores version_string' do
      version = described_class.new('2.0')
      expect(version.version_string).to eq('2.0')
    end

    it 'stores options' do
      options = { info: { title: 'Test API' } }
      version = described_class.new('2.0', options)
      expect(version.options).to eq(options)
    end

    it 'defaults options to empty hash' do
      version = described_class.new('2.0')
      expect(version.options).to eq({})
    end
  end

  describe '#swagger_2_0?' do
    it 'returns true for 2.0' do
      version = described_class.new('2.0')
      expect(version.swagger_2_0?).to be true
    end

    it 'returns false for 3.1.0' do
      version = described_class.new('3.1.0')
      expect(version.swagger_2_0?).to be false
    end
  end

  describe '#openapi_3_1_0?' do
    it 'returns true for 3.1.0' do
      version = described_class.new('3.1.0')
      expect(version.openapi_3_1_0?).to be true
    end

    it 'returns false for 2.0' do
      version = described_class.new('2.0')
      expect(version.openapi_3_1_0?).to be false
    end
  end
end
