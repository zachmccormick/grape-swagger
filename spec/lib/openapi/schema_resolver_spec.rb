# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GrapeSwagger::OpenAPI::SchemaResolver do
  let(:swagger_version) { GrapeSwagger::OpenAPI::Version.new(GrapeSwagger::OpenAPI::VersionConstants::SWAGGER_2_0) }
  let(:openapi_version) { GrapeSwagger::OpenAPI::Version.new(GrapeSwagger::OpenAPI::VersionConstants::OPENAPI_3_1_0) }

  describe '.translate_ref' do
    context 'with Swagger 2.0' do
      it 'does not translate definitions references' do
        ref = '#/definitions/User'
        result = described_class.translate_ref(ref, swagger_version)
        expect(result).to eq('#/definitions/User')
      end

      it 'does not translate responses references' do
        ref = '#/responses/NotFound'
        result = described_class.translate_ref(ref, swagger_version)
        expect(result).to eq('#/responses/NotFound')
      end

      it 'does not translate parameters references' do
        ref = '#/parameters/PageLimit'
        result = described_class.translate_ref(ref, swagger_version)
        expect(result).to eq('#/parameters/PageLimit')
      end

      it 'keeps external references unchanged' do
        ref = 'external.json#/definitions/Model'
        result = described_class.translate_ref(ref, swagger_version)
        expect(result).to eq('external.json#/definitions/Model')
      end
    end

    context 'with OpenAPI 3.1.0' do
      it 'translates #/definitions/ to #/components/schemas/' do
        ref = '#/definitions/User'
        result = described_class.translate_ref(ref, openapi_version)
        expect(result).to eq('#/components/schemas/User')
      end

      it 'translates #/responses/ to #/components/responses/' do
        ref = '#/responses/NotFound'
        result = described_class.translate_ref(ref, openapi_version)
        expect(result).to eq('#/components/responses/NotFound')
      end

      it 'translates #/parameters/ to #/components/parameters/' do
        ref = '#/parameters/PageLimit'
        result = described_class.translate_ref(ref, openapi_version)
        expect(result).to eq('#/components/parameters/PageLimit')
      end

      it 'translates external references' do
        ref = 'external.json#/definitions/Model'
        result = described_class.translate_ref(ref, openapi_version)
        expect(result).to eq('external.json#/components/schemas/Model')
      end

      it 'keeps already-translated references unchanged' do
        ref = '#/components/schemas/User'
        result = described_class.translate_ref(ref, openapi_version)
        expect(result).to eq('#/components/schemas/User')
      end

      it 'handles complex model names with underscores' do
        ref = '#/definitions/User_Profile'
        result = described_class.translate_ref(ref, openapi_version)
        expect(result).to eq('#/components/schemas/User_Profile')
      end

      it 'handles complex model names with numbers' do
        ref = '#/definitions/Model123'
        result = described_class.translate_ref(ref, openapi_version)
        expect(result).to eq('#/components/schemas/Model123')
      end
    end
  end

  describe '.translate_schema' do
    context 'with Swagger 2.0' do
      it 'does not translate simple schema references' do
        schema = { '$ref' => '#/definitions/User' }
        result = described_class.translate_schema(schema, swagger_version)
        expect(result).to eq({ '$ref' => '#/definitions/User' })
      end

      it 'does not translate nested references in properties' do
        schema = {
          'type' => 'object',
          'properties' => {
            'user' => { '$ref' => '#/definitions/User' },
            'account' => { '$ref' => '#/definitions/Account' }
          }
        }
        result = described_class.translate_schema(schema, swagger_version)
        expect(result['properties']['user']['$ref']).to eq('#/definitions/User')
        expect(result['properties']['account']['$ref']).to eq('#/definitions/Account')
      end
    end

    context 'with OpenAPI 3.1.0' do
      it 'translates simple schema references' do
        schema = { '$ref' => '#/definitions/User' }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result).to eq({ '$ref' => '#/components/schemas/User' })
      end

      it 'translates nested references in properties' do
        schema = {
          'type' => 'object',
          'properties' => {
            'user' => { '$ref' => '#/definitions/User' },
            'account' => { '$ref' => '#/definitions/Account' }
          }
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result['properties']['user']['$ref']).to eq('#/components/schemas/User')
        expect(result['properties']['account']['$ref']).to eq('#/components/schemas/Account')
      end

      it 'translates array item references' do
        schema = {
          'type' => 'array',
          'items' => { '$ref' => '#/definitions/User' }
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result['items']['$ref']).to eq('#/components/schemas/User')
      end

      it 'translates allOf references' do
        schema = {
          'allOf' => [
            { '$ref' => '#/definitions/BaseModel' },
            { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } } }
          ]
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result['allOf'][0]['$ref']).to eq('#/components/schemas/BaseModel')
      end

      it 'translates oneOf references' do
        schema = {
          'oneOf' => [
            { '$ref' => '#/definitions/User' },
            { '$ref' => '#/definitions/Guest' }
          ]
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result['oneOf'][0]['$ref']).to eq('#/components/schemas/User')
        expect(result['oneOf'][1]['$ref']).to eq('#/components/schemas/Guest')
      end

      it 'translates anyOf references' do
        schema = {
          'anyOf' => [
            { '$ref' => '#/definitions/EmailContact' },
            { '$ref' => '#/definitions/PhoneContact' }
          ]
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result['anyOf'][0]['$ref']).to eq('#/components/schemas/EmailContact')
        expect(result['anyOf'][1]['$ref']).to eq('#/components/schemas/PhoneContact')
      end

      it 'translates not references' do
        schema = {
          'not' => { '$ref' => '#/definitions/InvalidModel' }
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result['not']['$ref']).to eq('#/components/schemas/InvalidModel')
      end

      it 'handles deeply nested references' do
        schema = {
          'type' => 'object',
          'properties' => {
            'users' => {
              'type' => 'array',
              'items' => {
                'allOf' => [
                  { '$ref' => '#/definitions/BaseUser' },
                  {
                    'type' => 'object',
                    'properties' => {
                      'profile' => { '$ref' => '#/definitions/Profile' }
                    }
                  }
                ]
              }
            }
          }
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result['properties']['users']['items']['allOf'][0]['$ref']).to eq('#/components/schemas/BaseUser')
        expect(result['properties']['users']['items']['allOf'][1]['properties']['profile']['$ref']).to eq('#/components/schemas/Profile')
      end

      it 'handles circular references without infinite loop' do
        schema = {
          'type' => 'object',
          'properties' => {
            'parent' => { '$ref' => '#/definitions/Node' },
            'children' => {
              'type' => 'array',
              'items' => { '$ref' => '#/definitions/Node' }
            }
          }
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result['properties']['parent']['$ref']).to eq('#/components/schemas/Node')
        expect(result['properties']['children']['items']['$ref']).to eq('#/components/schemas/Node')
      end

      it 'does not modify schemas without references' do
        schema = {
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string' },
            'age' => { 'type' => 'integer' }
          }
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result).to eq(schema)
      end

      it 'preserves other schema properties during translation' do
        schema = {
          '$ref' => '#/definitions/User',
          'description' => 'A user object',
          'example' => { 'name' => 'John' }
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result['$ref']).to eq('#/components/schemas/User')
        expect(result['description']).to eq('A user object')
        expect(result['example']).to eq({ 'name' => 'John' })
      end
    end
  end

  describe '.translate_components' do
    context 'with Swagger 2.0' do
      it 'returns definitions unchanged' do
        definitions = {
          'User' => { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } } },
          'Account' => { 'type' => 'object', 'properties' => { 'owner' => { '$ref' => '#/definitions/User' } } }
        }
        result = described_class.translate_components(definitions, swagger_version)
        expect(result['Account']['properties']['owner']['$ref']).to eq('#/definitions/User')
      end
    end

    context 'with OpenAPI 3.1.0' do
      it 'translates references within schema definitions' do
        schemas = {
          'User' => { 'type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } } },
          'Account' => { 'type' => 'object', 'properties' => { 'owner' => { '$ref' => '#/definitions/User' } } }
        }
        result = described_class.translate_components(schemas, openapi_version)
        expect(result['Account']['properties']['owner']['$ref']).to eq('#/components/schemas/User')
      end

      it 'translates multiple references in a single schema' do
        schemas = {
          'UserAccount' => {
            'type' => 'object',
            'properties' => {
              'user' => { '$ref' => '#/definitions/User' },
              'billing' => { '$ref' => '#/definitions/Billing' },
              'settings' => { '$ref' => '#/definitions/Settings' }
            }
          }
        }
        result = described_class.translate_components(schemas, openapi_version)
        expect(result['UserAccount']['properties']['user']['$ref']).to eq('#/components/schemas/User')
        expect(result['UserAccount']['properties']['billing']['$ref']).to eq('#/components/schemas/Billing')
        expect(result['UserAccount']['properties']['settings']['$ref']).to eq('#/components/schemas/Settings')
      end

      it 'handles empty schemas hash' do
        schemas = {}
        result = described_class.translate_components(schemas, openapi_version)
        expect(result).to eq({})
      end

      it 'applies nullable transformation to schemas' do
        schema = {
          type: 'string',
          nullable: true
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result[:type]).to eq(['string', 'null'])
        expect(result).not_to have_key(:nullable)
      end

      it 'applies binary encoding transformation to schemas' do
        schema = {
          type: 'string',
          format: 'binary'
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result[:type]).to eq('string')
        expect(result[:contentEncoding]).to eq('base64')
        expect(result[:contentMediaType]).to eq('application/octet-stream')
        expect(result).not_to have_key(:format)
      end

      it 'applies both nullable and binary transformations' do
        schema = {
          type: 'string',
          format: 'binary',
          nullable: true
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result[:type]).to eq(['string', 'null'])
        expect(result[:contentEncoding]).to eq('base64')
        expect(result[:contentMediaType]).to eq('application/octet-stream')
        expect(result).not_to have_key(:format)
        expect(result).not_to have_key(:nullable)
      end

      it 'transforms nested nullable properties' do
        schema = {
          type: 'object',
          properties: {
            name: { type: 'string', nullable: true },
            age: { type: 'integer', nullable: true }
          }
        }
        result = described_class.translate_schema(schema, openapi_version)
        expect(result[:properties][:name][:type]).to eq(['string', 'null'])
        expect(result[:properties][:age][:type]).to eq(['integer', 'null'])
      end
    end
  end
end
