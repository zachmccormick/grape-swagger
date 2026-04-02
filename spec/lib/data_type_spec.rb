# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::DocMethods::DataType do
  subject { described_class.call(value) }

  describe 'standards' do
    ['Boolean', Date, Integer, String, Float].each do |type|
      specify do
        data_type = described_class.call(type: type)
        expect(data_type).to eql type.to_s.downcase
      end
    end
  end

  describe 'Hash' do
    let(:value) { { type: Hash } }

    it { is_expected.to eq 'object' }
  end

  describe 'Multi types in a string' do
    let(:value) { { type: '[String, Integer]' } }

    it { is_expected.to eq 'string' }
  end

  describe 'Multi types in a string stating with A' do
    let(:value) { { type: '[Apple, Orange]' } }

    it { is_expected.to eq 'Apple' }
  end

  describe 'Multi types in array' do
    let(:value) { { type: [String, Integer] } }

    it { is_expected.to eq 'string' }
  end

  describe 'Types in array with entity_name' do
    before do
      stub_const 'MyEntity', Class.new
      allow(MyEntity).to receive(:entity_name).and_return 'MyInteger'
    end

    let(:value) { { type: '[MyEntity]' } }

    it { is_expected.to eq 'MyInteger' }
  end

  describe 'Types in array with inherited entity_name' do
    before do
      stub_const 'EntityBase', Class.new
      allow(EntityBase).to receive(:entity_name).and_return 'MyInteger'
      stub_const 'MyEntity', Class.new(EntityBase)
    end

    let(:value) { { type: '[MyEntity]' } }

    it { is_expected.to eq 'MyInteger' }
  end

  describe 'Rack::Multipart::UploadedFile' do
    let(:value) { { type: Rack::Multipart::UploadedFile } }

    it { is_expected.to eq 'file' }
  end

  describe 'Grape::API::Boolean' do
    let(:value) { { type: Grape::API::Boolean } }

    it { is_expected.to eq 'boolean' }
  end

  describe 'BigDecimal' do
    let(:value) { { type: BigDecimal } }

    it { is_expected.to eq 'double' }
  end

  describe 'DateTime' do
    let(:value) { { type: DateTime } }

    it { is_expected.to eq 'dateTime' }
  end

  describe 'Numeric' do
    let(:value) { { type: Numeric } }

    it { is_expected.to eq 'long' }
  end

  describe 'Symbol' do
    let(:value) { { type: Symbol } }

    it { is_expected.to eq 'string' }
  end

  describe '[String]' do
    let(:value) { { type: '[String]' } }

    it { is_expected.to eq('string') }
  end

  describe '[Integer]' do
    let(:value) { { type: '[Integer]' } }

    it { is_expected.to eq('integer') }
  end

  describe 'OpenAPI 3.1.0 type mappings via .mapping' do
    context 'with version 3.1.0' do
      it 'returns hash with type for integer' do
        result = described_class.mapping('integer', '3.1.0')
        expect(result).to eq({ type: 'integer' })
      end

      it 'returns hash with type and constraints for long' do
        result = described_class.mapping('long', '3.1.0')
        expect(result[:type]).to eq('integer')
        expect(result[:minimum]).to eq(-2**63)
        expect(result[:maximum]).to eq((2**63) - 1)
      end

      it 'returns hash with type for float' do
        result = described_class.mapping('float', '3.1.0')
        expect(result).to eq({ type: 'number' })
      end

      it 'returns hash with contentEncoding for binary' do
        result = described_class.mapping('binary', '3.1.0')
        expect(result[:type]).to eq('string')
        expect(result[:contentEncoding]).to eq('base64')
        expect(result[:contentMediaType]).to eq('application/octet-stream')
      end

      it 'returns hash with format for date' do
        result = described_class.mapping('date', '3.1.0')
        expect(result).to eq({ type: 'string', format: 'date' })
      end

      it 'returns hash with format for email' do
        result = described_class.mapping('email', '3.1.0')
        expect(result).to eq({ type: 'string', format: 'email' })
      end
    end

    context 'without version (defaults to Swagger 2.0)' do
      it 'returns array [type, format] for integer' do
        result = described_class.mapping('integer')
        expect(result).to eq(%w[integer int32])
      end

      it 'returns array [type, format] for date' do
        result = described_class.mapping('date')
        expect(result).to eq(%w[string date])
      end
    end
  end
end
