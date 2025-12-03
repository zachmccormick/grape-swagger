# frozen_string_literal: true

require 'spec_helper'

# Integration tests for nullable and binary handling in OpenAPI 3.1.0
describe 'Nullable and Binary Handling Integration' do
  let(:version_3_1_0) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe 'End-to-end nullable transformation' do
    it 'transforms complete schema with nullable fields' do
      schema = {
        type: 'object',
        properties: {
          id: { type: 'integer' },
          name: { type: 'string', nullable: true },
          email: { type: 'string', format: 'email', nullable: true },
          age: { type: 'integer', nullable: true },
          active: { type: 'boolean', nullable: true },
          tags: { type: 'array', items: { type: 'string' }, nullable: true }
        }
      }

      result = GrapeSwagger::OpenAPI::SchemaResolver.translate_schema(schema, version_3_1_0)

      expect(result[:properties][:id][:type]).to eq('integer')
      expect(result[:properties][:name][:type]).to eq(%w[string null])
      expect(result[:properties][:email][:type]).to eq(%w[string null])
      expect(result[:properties][:email][:format]).to eq('email')
      expect(result[:properties][:age][:type]).to eq(%w[integer null])
      expect(result[:properties][:active][:type]).to eq(%w[boolean null])
      expect(result[:properties][:tags][:type]).to eq(%w[array null])
      expect(result[:properties][:tags][:items]).to eq({ type: 'string' })
    end
  end

  describe 'End-to-end binary transformation' do
    it 'transforms file upload schema with binary format' do
      schema = {
        type: 'object',
        properties: {
          document: { type: 'string', format: 'binary', description: 'PDF document' },
          image: { type: 'string', format: 'binary', contentMediaType: 'image/png' },
          data: { type: 'string', format: 'byte', description: 'Base64 data' }
        }
      }

      result = GrapeSwagger::OpenAPI::SchemaResolver.translate_schema(schema, version_3_1_0)

      expect(result[:properties][:document][:type]).to eq('string')
      expect(result[:properties][:document][:contentEncoding]).to eq('base64')
      expect(result[:properties][:document][:contentMediaType]).to eq('application/octet-stream')
      expect(result[:properties][:document][:description]).to eq('PDF document')
      expect(result[:properties][:document]).not_to have_key(:format)

      expect(result[:properties][:image][:contentEncoding]).to eq('base64')
      expect(result[:properties][:image][:contentMediaType]).to eq('image/png')

      expect(result[:properties][:data][:contentEncoding]).to eq('base64')
      expect(result[:properties][:data]).not_to have_key(:contentMediaType)
      expect(result[:properties][:data][:description]).to eq('Base64 data')
    end
  end

  describe 'Combined nullable and binary transformations' do
    it 'handles schema with both nullable and binary fields' do
      schema = {
        type: 'object',
        properties: {
          user_id: { type: 'integer' },
          avatar: { type: 'string', format: 'binary', nullable: true },
          resume: { type: 'string', format: 'binary', nullable: true, contentMediaType: 'application/pdf' },
          bio: { type: 'string', nullable: true }
        }
      }

      result = GrapeSwagger::OpenAPI::SchemaResolver.translate_schema(schema, version_3_1_0)

      # Regular field
      expect(result[:properties][:user_id][:type]).to eq('integer')

      # Nullable binary field with default media type
      expect(result[:properties][:avatar][:type]).to eq(%w[string null])
      expect(result[:properties][:avatar][:contentEncoding]).to eq('base64')
      expect(result[:properties][:avatar][:contentMediaType]).to eq('application/octet-stream')
      expect(result[:properties][:avatar]).not_to have_key(:format)
      expect(result[:properties][:avatar]).not_to have_key(:nullable)

      # Nullable binary field with custom media type
      expect(result[:properties][:resume][:type]).to eq(%w[string null])
      expect(result[:properties][:resume][:contentEncoding]).to eq('base64')
      expect(result[:properties][:resume][:contentMediaType]).to eq('application/pdf')
      expect(result[:properties][:resume]).not_to have_key(:format)
      expect(result[:properties][:resume]).not_to have_key(:nullable)

      # Regular nullable field
      expect(result[:properties][:bio][:type]).to eq(%w[string null])
      expect(result[:properties][:bio]).not_to have_key(:nullable)
    end
  end

  describe 'Swagger 2.0 backward compatibility' do
    it 'preserves nullable and binary format for Swagger 2.0' do
      schema = {
        type: 'object',
        properties: {
          name: { type: 'string', nullable: true },
          file: { type: 'string', format: 'binary' }
        }
      }

      result = GrapeSwagger::OpenAPI::SchemaResolver.translate_schema(schema, version_2_0)

      expect(result[:properties][:name][:type]).to eq('string')
      expect(result[:properties][:name][:nullable]).to eq(true)
      expect(result[:properties][:file][:format]).to eq('binary')
      expect(result[:properties][:file]).not_to have_key(:contentEncoding)
    end
  end

  describe 'Deeply nested schemas' do
    it 'transforms nullable and binary in deeply nested structures' do
      schema = {
        type: 'object',
        properties: {
          users: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                name: { type: 'string', nullable: true },
                avatar: { type: 'string', format: 'binary', nullable: true }
              }
            }
          }
        }
      }

      result = GrapeSwagger::OpenAPI::SchemaResolver.translate_schema(schema, version_3_1_0)

      user_props = result[:properties][:users][:items][:properties]
      expect(user_props[:name][:type]).to eq(%w[string null])
      expect(user_props[:avatar][:type]).to eq(%w[string null])
      expect(user_props[:avatar][:contentEncoding]).to eq('base64')
      expect(user_props[:avatar][:contentMediaType]).to eq('application/octet-stream')
    end
  end

  describe 'Real-world file upload scenario' do
    it 'transforms multipart file upload with metadata' do
      schema = {
        type: 'object',
        properties: {
          file: {
            type: 'string',
            format: 'binary',
            description: 'File to upload'
          },
          filename: {
            type: 'string',
            description: 'Original filename'
          },
          content_type: {
            type: 'string',
            nullable: true,
            description: 'MIME type of the file'
          }
        },
        required: %w[file filename]
      }

      result = GrapeSwagger::OpenAPI::SchemaResolver.translate_schema(schema, version_3_1_0)

      expect(result[:properties][:file][:type]).to eq('string')
      expect(result[:properties][:file][:contentEncoding]).to eq('base64')
      expect(result[:properties][:file][:contentMediaType]).to eq('application/octet-stream')
      expect(result[:properties][:file][:description]).to eq('File to upload')

      expect(result[:properties][:filename][:type]).to eq('string')

      expect(result[:properties][:content_type][:type]).to eq(%w[string null])
      expect(result[:properties][:content_type][:description]).to eq('MIME type of the file')

      expect(result[:required]).to eq(%w[file filename])
    end
  end

  describe 'Components/definitions transformation' do
    it 'applies transformations to all schemas in components' do
      components = {
        'User' => {
          type: 'object',
          properties: {
            id: { type: 'integer' },
            name: { type: 'string', nullable: true },
            avatar: { type: 'string', format: 'binary', nullable: true }
          }
        },
        'Document' => {
          type: 'object',
          properties: {
            content: { type: 'string', format: 'binary' },
            title: { type: 'string', nullable: true }
          }
        }
      }

      result = GrapeSwagger::OpenAPI::SchemaResolver.translate_components(components, version_3_1_0)

      # User schema
      expect(result['User'][:properties][:id][:type]).to eq('integer')
      expect(result['User'][:properties][:name][:type]).to eq(%w[string null])
      expect(result['User'][:properties][:avatar][:type]).to eq(%w[string null])
      expect(result['User'][:properties][:avatar][:contentEncoding]).to eq('base64')

      # Document schema
      expect(result['Document'][:properties][:content][:contentEncoding]).to eq('base64')
      expect(result['Document'][:properties][:title][:type]).to eq(%w[string null])
    end
  end
end
