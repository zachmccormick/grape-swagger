# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::TypeMapper do
  describe '.map' do
    context 'OpenAPI 3.1.0 type mappings' do
      context 'integer types' do
        it 'maps integer to {type: "integer"} without format' do
          result = described_class.map('integer', '3.1.0')
          expect(result).to eq({ type: 'integer' })
          expect(result).not_to have_key(:format)
        end

        it 'maps long to {type: "integer"} with min/max constraints' do
          result = described_class.map('long', '3.1.0')
          expect(result[:type]).to eq('integer')
          expect(result[:minimum]).to eq(-2**63)
          expect(result[:maximum]).to eq((2**63) - 1)
          expect(result).not_to have_key(:format)
        end
      end

      context 'number types' do
        it 'maps float to {type: "number"} without format' do
          result = described_class.map('float', '3.1.0')
          expect(result).to eq({ type: 'number' })
          expect(result).not_to have_key(:format)
        end

        it 'maps double to {type: "number"} without format' do
          result = described_class.map('double', '3.1.0')
          expect(result).to eq({ type: 'number' })
          expect(result).not_to have_key(:format)
        end
      end

      context 'binary types with contentEncoding' do
        it 'maps binary to {type: "string"} with contentEncoding and contentMediaType' do
          result = described_class.map('binary', '3.1.0')
          expect(result[:type]).to eq('string')
          expect(result[:contentEncoding]).to eq('base64')
          expect(result[:contentMediaType]).to eq('application/octet-stream')
          expect(result).not_to have_key(:format)
        end

        it 'maps byte to {type: "string"} with contentEncoding only' do
          result = described_class.map('byte', '3.1.0')
          expect(result[:type]).to eq('string')
          expect(result[:contentEncoding]).to eq('base64')
          expect(result).not_to have_key(:format)
          expect(result).not_to have_key(:contentMediaType)
        end
      end

      context 'date/time formats as annotations' do
        it 'maps date to {type: "string", format: "date"}' do
          result = described_class.map('date', '3.1.0')
          expect(result).to eq({ type: 'string', format: 'date' })
        end

        it 'maps dateTime to {type: "string", format: "date-time"}' do
          result = described_class.map('dateTime', '3.1.0')
          expect(result).to eq({ type: 'string', format: 'date-time' })
        end
      end

      context 'string format annotations' do
        it 'maps email to {type: "string", format: "email"}' do
          result = described_class.map('email', '3.1.0')
          expect(result).to eq({ type: 'string', format: 'email' })
        end

        it 'maps uuid to {type: "string", format: "uuid"}' do
          result = described_class.map('uuid', '3.1.0')
          expect(result).to eq({ type: 'string', format: 'uuid' })
        end

        it 'maps uri to {type: "string", format: "uri"}' do
          result = described_class.map('uri', '3.1.0')
          expect(result).to eq({ type: 'string', format: 'uri' })
        end

        it 'maps hostname to {type: "string", format: "hostname"}' do
          result = described_class.map('hostname', '3.1.0')
          expect(result).to eq({ type: 'string', format: 'hostname' })
        end

        it 'maps ipv4 to {type: "string", format: "ipv4"}' do
          result = described_class.map('ipv4', '3.1.0')
          expect(result).to eq({ type: 'string', format: 'ipv4' })
        end

        it 'maps ipv6 to {type: "string", format: "ipv6"}' do
          result = described_class.map('ipv6', '3.1.0')
          expect(result).to eq({ type: 'string', format: 'ipv6' })
        end

        it 'maps password to {type: "string", format: "password"}' do
          result = described_class.map('password', '3.1.0')
          expect(result).to eq({ type: 'string', format: 'password' })
        end
      end

      context 'basic types' do
        it 'maps string to {type: "string"}' do
          result = described_class.map('string', '3.1.0')
          expect(result).to eq({ type: 'string' })
        end

        it 'maps boolean to {type: "boolean"}' do
          result = described_class.map('boolean', '3.1.0')
          expect(result).to eq({ type: 'boolean' })
        end
      end

      context 'unknown types' do
        it 'defaults unknown types to {type: "string"}' do
          result = described_class.map('unknown_type', '3.1.0')
          expect(result).to eq({ type: 'string' })
        end
      end
    end

    context 'Swagger 2.0 backward compatibility' do
      it 'uses legacy mapping for Swagger 2.0' do
        result = described_class.map('integer', '2.0')
        expect(result).to eq(%w[integer int32])
      end

      it 'maps long to [integer, int64] for Swagger 2.0' do
        result = described_class.map('long', '2.0')
        expect(result).to eq(%w[integer int64])
      end

      it 'maps float to [number, float] for Swagger 2.0' do
        result = described_class.map('float', '2.0')
        expect(result).to eq(%w[number float])
      end

      it 'maps double to [number, double] for Swagger 2.0' do
        result = described_class.map('double', '2.0')
        expect(result).to eq(%w[number double])
      end

      it 'maps byte to [string, byte] for Swagger 2.0' do
        result = described_class.map('byte', '2.0')
        expect(result).to eq(%w[string byte])
      end

      it 'maps binary to [string, binary] for Swagger 2.0' do
        result = described_class.map('binary', '2.0')
        expect(result).to eq(%w[string binary])
      end

      it 'maps date to [string, date] for Swagger 2.0' do
        result = described_class.map('date', '2.0')
        expect(result).to eq(%w[string date])
      end

      it 'maps dateTime to [string, date-time] for Swagger 2.0' do
        result = described_class.map('dateTime', '2.0')
        expect(result).to eq(%w[string date-time])
      end

      it 'maps password to [string, password] for Swagger 2.0' do
        result = described_class.map('password', '2.0')
        expect(result).to eq(%w[string password])
      end

      it 'maps email to [string, email] for Swagger 2.0' do
        result = described_class.map('email', '2.0')
        expect(result).to eq(%w[string email])
      end

      it 'maps uuid to [string, uuid] for Swagger 2.0' do
        result = described_class.map('uuid', '2.0')
        expect(result).to eq(%w[string uuid])
      end

      it 'defaults to "string" for unknown types in Swagger 2.0' do
        result = described_class.map('unknown', '2.0')
        expect(result).to eq('string')
      end
    end

    context 'when version is not specified' do
      it 'defaults to OpenAPI 3.1.0 behavior' do
        result = described_class.map('integer')
        expect(result).to eq({ type: 'integer' })
      end
    end
  end

  describe '.map_with_type_array' do
    context 'single type' do
      it 'returns type as string for single type' do
        result = described_class.map_with_type_array('string', '3.1.0')
        expect(result).to eq({ type: 'string' })
      end

      it 'preserves format for single type' do
        result = described_class.map_with_type_array('email', '3.1.0')
        expect(result).to eq({ type: 'string', format: 'email' })
      end
    end

    context 'type arrays' do
      it 'returns type as array for multiple types' do
        result = described_class.map_with_type_array(%w[string number], '3.1.0')
        expect(result[:type]).to eq(%w[string number])
      end

      it 'removes duplicate types from array' do
        result = described_class.map_with_type_array(%w[string string number], '3.1.0')
        expect(result[:type]).to eq(%w[string number])
      end

      it 'handles type array with null' do
        result = described_class.map_with_type_array(%w[string null], '3.1.0')
        expect(result[:type]).to eq(%w[string null])
      end

      it 'rejects empty type array' do
        expect do
          described_class.map_with_type_array([], '3.1.0')
        end.to raise_error(ArgumentError, 'Type array cannot be empty')
      end

      it 'does not include format for type arrays' do
        result = described_class.map_with_type_array(%w[string number], '3.1.0')
        expect(result).not_to have_key(:format)
      end
    end

    context 'Swagger 2.0 compatibility' do
      it 'does not support type arrays in Swagger 2.0' do
        result = described_class.map_with_type_array(%w[string number], '2.0')
        # Should only return the first type for backward compatibility
        expect(result).to eq('string')
      end
    end
  end

  describe '.to_json_schema_type' do
    it 'converts OpenAPI 3.1.0 mapping to JSON Schema type' do
      mapping = { type: 'integer' }
      result = described_class.to_json_schema_type(mapping)
      expect(result).to eq({ type: 'integer' })
    end

    it 'preserves format annotations' do
      mapping = { type: 'string', format: 'email' }
      result = described_class.to_json_schema_type(mapping)
      expect(result).to eq({ type: 'string', format: 'email' })
    end

    it 'preserves contentEncoding' do
      mapping = { type: 'string', contentEncoding: 'base64' }
      result = described_class.to_json_schema_type(mapping)
      expect(result).to eq({ type: 'string', contentEncoding: 'base64' })
    end

    it 'preserves type arrays' do
      mapping = { type: %w[string number] }
      result = described_class.to_json_schema_type(mapping)
      expect(result).to eq({ type: %w[string number] })
    end

    it 'preserves constraints (minimum, maximum)' do
      mapping = { type: 'integer', minimum: -2**63, maximum: (2**63) - 1 }
      result = described_class.to_json_schema_type(mapping)
      expect(result[:minimum]).to eq(-2**63)
      expect(result[:maximum]).to eq((2**63) - 1)
    end
  end
end
