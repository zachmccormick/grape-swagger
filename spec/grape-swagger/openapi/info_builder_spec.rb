# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::InfoBuilder do
  describe '.build' do
    context 'with minimal info' do
      it 'creates info object with title' do
        options = { info: { title: 'Test API' } }
        info = described_class.build(options)
        expect(info[:title]).to eq('Test API')
      end

      it 'includes default version when not specified' do
        options = { info: { title: 'Test API' } }
        info = described_class.build(options)
        expect(info[:version]).to eq('0.0.1')
      end
    end

    context 'with full info object' do
      let(:full_info) do
        {
          title: 'Comprehensive API',
          version: '1.2.3',
          description: 'A comprehensive API description',
          termsOfService: 'https://example.com/terms',
          contact: {
            name: 'API Support',
            url: 'https://example.com/support',
            email: 'support@example.com'
          },
          license: {
            name: 'Apache 2.0',
            url: 'https://www.apache.org/licenses/LICENSE-2.0.html'
          }
        }
      end

      it 'includes all info fields' do
        options = { info: full_info }
        info = described_class.build(options)

        expect(info[:title]).to eq('Comprehensive API')
        expect(info[:version]).to eq('1.2.3')
        expect(info[:description]).to eq('A comprehensive API description')
        expect(info[:termsOfService]).to eq('https://example.com/terms')
      end

      it 'includes contact object' do
        options = { info: full_info }
        info = described_class.build(options)

        expect(info[:contact]).to be_a(Hash)
        expect(info[:contact][:name]).to eq('API Support')
        expect(info[:contact][:url]).to eq('https://example.com/support')
        expect(info[:contact][:email]).to eq('support@example.com')
      end

      it 'includes license object' do
        options = { info: full_info }
        info = described_class.build(options)

        expect(info[:license]).to be_a(Hash)
        expect(info[:license][:name]).to eq('Apache 2.0')
        expect(info[:license][:url]).to eq('https://www.apache.org/licenses/LICENSE-2.0.html')
      end
    end

    context 'with legacy fields' do
      it 'converts base_path to x-base-path extension' do
        options = {
          info: { title: 'Test API' },
          base_path: '/api/v1'
        }
        info = described_class.build(options)
        expect(info[:'x-base-path']).to eq('/api/v1')
      end

      it 'does not include swagger-specific fields in info' do
        options = {
          info: { title: 'Test API' },
          host: 'api.example.com',
          schemes: ['https']
        }
        info = described_class.build(options)

        expect(info).not_to have_key(:host)
        expect(info).not_to have_key(:schemes)
      end
    end

    context 'when info is missing' do
      it 'raises an error' do
        options = {}
        expect { described_class.build(options) }.to raise_error(ArgumentError, /info is required/)
      end
    end
  end
end
