# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::ComponentsRegistry do
  before(:each) do
    described_class.reset!
  end

  describe '.register_parameter' do
    it 'registers a parameter class by name' do
      mock_class = Class.new do
        def self.name
          'PageParam'
        end

        def self.component_name
          nil
        end

        def self.to_openapi
          { name: 'page', in: 'query', schema: { type: 'integer' } }
        end
      end

      described_class.register_parameter(mock_class)

      expect(described_class.parameters).to have_key('PageParam')
      expect(described_class.parameters['PageParam']).to eq(mock_class)
    end
  end

  describe '.register_response' do
    it 'registers a response class by name' do
      mock_class = Class.new do
        def self.name
          'NotFoundResponse'
        end

        def self.component_name
          nil
        end

        def self.to_openapi
          { description: 'Not found' }
        end
      end

      described_class.register_response(mock_class)

      expect(described_class.responses).to have_key('NotFoundResponse')
    end
  end

  describe '.register_header' do
    it 'registers a header class by name' do
      mock_class = Class.new do
        def self.name
          'RateLimitHeader'
        end

        def self.component_name
          nil
        end

        def self.to_openapi
          { description: 'Rate limit', schema: { type: 'integer' } }
        end
      end

      described_class.register_header(mock_class)

      expect(described_class.headers).to have_key('RateLimitHeader')
    end
  end

  describe '.reset!' do
    it 'clears all registries' do
      mock_class = Class.new do
        def self.name
          'TestParam'
        end

        def self.component_name
          nil
        end
      end

      described_class.register_parameter(mock_class)
      described_class.reset!

      expect(described_class.parameters).to be_empty
    end
  end

  describe '.component_name_for' do
    context 'with nested class names' do
      it 'extracts the last part of the class name' do
        mock_class = Class.new do
          def self.name
            'Api::V1::PageParam'
          end

          def self.component_name
            nil
          end
        end

        result = described_class.component_name_for(mock_class)
        expect(result).to eq('PageParam')
      end
    end

    context 'with custom component_name' do
      it 'uses the custom component_name when provided' do
        mock_class = Class.new do
          def self.name
            'Api::V1::PageParam'
          end

          def self.component_name
            'CustomPageParam'
          end
        end

        result = described_class.component_name_for(mock_class)
        expect(result).to eq('CustomPageParam')
      end
    end

    context 'with anonymous class' do
      it 'raises an error when anonymous class has no component_name' do
        mock_class = Class.new do
          def self.name
            nil
          end

          def self.component_name
            nil
          end
        end

        expect do
          described_class.component_name_for(mock_class)
        end.to raise_error(ArgumentError, /Cannot determine component name/)
      end
    end
  end
end
