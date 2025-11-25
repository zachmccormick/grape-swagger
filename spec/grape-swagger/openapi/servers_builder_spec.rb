# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::ServersBuilder do
  describe '.build' do
    context 'with explicit servers array' do
      it 'returns the servers array as-is' do
        options = {
          servers: [
            { url: 'https://api.example.com/v1', description: 'Production' },
            { url: 'https://staging-api.example.com/v1', description: 'Staging' }
          ]
        }
        servers = described_class.build(options)
        expect(servers).to be_an(Array)
        expect(servers.size).to eq(2)
        expect(servers[0][:url]).to eq('https://api.example.com/v1')
        expect(servers[0][:description]).to eq('Production')
        expect(servers[1][:url]).to eq('https://staging-api.example.com/v1')
      end

      it 'supports server variables' do
        options = {
          servers: [
            {
              url: 'https://{environment}.api.example.com/{version}',
              description: 'Multi-environment server',
              variables: {
                environment: {
                  default: 'production',
                  enum: ['production', 'staging', 'development']
                },
                version: {
                  default: 'v1'
                }
              }
            }
          ]
        }
        servers = described_class.build(options)

        expect(servers[0][:url]).to eq('https://{environment}.api.example.com/{version}')
        expect(servers[0][:variables]).to be_a(Hash)
        expect(servers[0][:variables][:environment][:default]).to eq('production')
        expect(servers[0][:variables][:environment][:enum]).to eq(['production', 'staging', 'development'])
        expect(servers[0][:variables][:version][:default]).to eq('v1')
      end
    end

    context 'with legacy host/basePath/schemes' do
      it 'converts single scheme with host and basePath' do
        options = {
          host: 'api.example.com',
          base_path: '/v1',
          schemes: ['https']
        }
        servers = described_class.build(options)

        expect(servers).to be_an(Array)
        expect(servers.size).to eq(1)
        expect(servers[0][:url]).to eq('https://api.example.com/v1')
      end

      it 'creates multiple servers for multiple schemes' do
        options = {
          host: 'api.example.com',
          base_path: '/v1',
          schemes: ['https', 'http']
        }
        servers = described_class.build(options)

        expect(servers.size).to eq(2)
        expect(servers[0][:url]).to eq('https://api.example.com/v1')
        expect(servers[1][:url]).to eq('http://api.example.com/v1')
      end

      it 'handles host without basePath' do
        options = {
          host: 'api.example.com',
          schemes: ['https']
        }
        servers = described_class.build(options)

        expect(servers[0][:url]).to eq('https://api.example.com')
      end

      it 'handles basePath without host' do
        options = {
          base_path: '/api/v1',
          schemes: ['https']
        }
        servers = described_class.build(options)

        expect(servers[0][:url]).to eq('/api/v1')
      end

      it 'defaults to https when no scheme provided' do
        options = {
          host: 'api.example.com',
          base_path: '/v1'
        }
        servers = described_class.build(options)

        expect(servers[0][:url]).to eq('https://api.example.com/v1')
      end

      it 'handles just basePath with no host or scheme' do
        options = {
          base_path: '/api'
        }
        servers = described_class.build(options)

        expect(servers[0][:url]).to eq('/api')
      end
    end

    context 'when no server configuration provided' do
      it 'returns empty array' do
        options = {}
        servers = described_class.build(options)
        expect(servers).to eq([])
      end
    end

    context 'precedence of server configuration' do
      it 'prefers servers array over legacy fields' do
        options = {
          servers: [{ url: 'https://new.api.com' }],
          host: 'old.api.com',
          base_path: '/v1',
          schemes: ['http']
        }
        servers = described_class.build(options)

        expect(servers.size).to eq(1)
        expect(servers[0][:url]).to eq('https://new.api.com')
      end
    end

    context 'with port in host' do
      it 'preserves port in URL' do
        options = {
          host: 'api.example.com:8080',
          base_path: '/v1',
          schemes: ['https']
        }
        servers = described_class.build(options)

        expect(servers[0][:url]).to eq('https://api.example.com:8080/v1')
      end
    end
  end
end
