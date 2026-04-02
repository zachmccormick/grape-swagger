# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::TypeMapper do
  describe '.map' do
    context 'integer types' do
      it 'maps integer to {type: "integer"} without format' do
        result = described_class.map('integer')
        expect(result).to eq({ type: 'integer' })
        expect(result).not_to have_key(:format)
      end

      it 'maps long to {type: "integer"} with min/max constraints' do
        result = described_class.map('long')
        expect(result[:type]).to eq('integer')
        expect(result[:minimum]).to eq(-2**63)
        expect(result[:maximum]).to eq((2**63) - 1)
        expect(result).not_to have_key(:format)
      end
    end

    context 'number types' do
      it 'maps float to {type: "number"} without format' do
        result = described_class.map('float')
        expect(result).to eq({ type: 'number' })
        expect(result).not_to have_key(:format)
      end

      it 'maps double to {type: "number"} without format' do
        result = described_class.map('double')
        expect(result).to eq({ type: 'number' })
        expect(result).not_to have_key(:format)
      end
    end

    context 'binary types with contentEncoding' do
      it 'maps binary to {type: "string"} with contentEncoding and contentMediaType' do
        result = described_class.map('binary')
        expect(result[:type]).to eq('string')
        expect(result[:contentEncoding]).to eq('base64')
        expect(result[:contentMediaType]).to eq('application/octet-stream')
        expect(result).not_to have_key(:format)
      end

      it 'maps byte to {type: "string"} with contentEncoding only' do
        result = described_class.map('byte')
        expect(result[:type]).to eq('string')
        expect(result[:contentEncoding]).to eq('base64')
        expect(result).not_to have_key(:format)
        expect(result).not_to have_key(:contentMediaType)
      end
    end

    context 'date/time formats' do
      it 'maps date to {type: "string", format: "date"}' do
        expect(described_class.map('date')).to eq({ type: 'string', format: 'date' })
      end

      it 'maps dateTime to {type: "string", format: "date-time"}' do
        expect(described_class.map('dateTime')).to eq({ type: 'string', format: 'date-time' })
      end
    end

    context 'string format annotations' do
      it('maps email') { expect(described_class.map('email')).to eq({ type: 'string', format: 'email' }) }
      it('maps uuid') { expect(described_class.map('uuid')).to eq({ type: 'string', format: 'uuid' }) }
      it('maps uri') { expect(described_class.map('uri')).to eq({ type: 'string', format: 'uri' }) }
      it('maps hostname') { expect(described_class.map('hostname')).to eq({ type: 'string', format: 'hostname' }) }
      it('maps ipv4') { expect(described_class.map('ipv4')).to eq({ type: 'string', format: 'ipv4' }) }
      it('maps ipv6') { expect(described_class.map('ipv6')).to eq({ type: 'string', format: 'ipv6' }) }
      it('maps password') { expect(described_class.map('password')).to eq({ type: 'string', format: 'password' }) }
    end

    context 'basic types' do
      it('maps string') { expect(described_class.map('string')).to eq({ type: 'string' }) }
      it('maps boolean') { expect(described_class.map('boolean')).to eq({ type: 'boolean' }) }
    end

    it 'defaults unknown types to {type: "string"}' do
      expect(described_class.map('unknown_type')).to eq({ type: 'string' })
    end
  end

  describe '.map_with_type_array' do
    it 'delegates single type to .map' do
      expect(described_class.map_with_type_array('string')).to eq({ type: 'string' })
    end

    it 'returns type as array for multiple types' do
      result = described_class.map_with_type_array(%w[string number])
      expect(result[:type]).to eq(%w[string number])
    end

    it 'deduplicates types' do
      result = described_class.map_with_type_array(%w[string string number])
      expect(result[:type]).to eq(%w[string number])
    end

    it 'handles type array with null' do
      result = described_class.map_with_type_array(%w[string null])
      expect(result[:type]).to eq(%w[string null])
    end

    it 'rejects empty type array' do
      expect { described_class.map_with_type_array([]) }.to raise_error(ArgumentError, 'Type array cannot be empty')
    end
  end

  describe '.to_json_schema_type' do
    it 'passes through type mappings unchanged' do
      expect(described_class.to_json_schema_type({ type: 'integer' })).to eq({ type: 'integer' })
    end

    it 'preserves contentEncoding' do
      mapping = { type: 'string', contentEncoding: 'base64' }
      expect(described_class.to_json_schema_type(mapping)).to eq(mapping)
    end

    it 'preserves type arrays' do
      mapping = { type: %w[string number] }
      expect(described_class.to_json_schema_type(mapping)).to eq(mapping)
    end
  end
end
