# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 Regression Suite' do
  let(:version_3_1) { GrapeSwagger::OpenAPI::Version.new('3.1.0') }
  let(:version_2_0) { GrapeSwagger::OpenAPI::Version.new('2.0') }

  describe 'backward compatibility' do
    it 'version selector defaults to Swagger 2.0' do
      result = GrapeSwagger::OpenAPI::VersionSelector.build_spec({})

      expect(result.swagger_2_0?).to be true
    end

    it 'supports explicit Swagger 2.0 version' do
      result = GrapeSwagger::OpenAPI::VersionSelector.build_spec(openapi_version: '2.0')

      expect(result.swagger_2_0?).to be true
      expect(result.openapi_3_1_0?).to be false
    end

    it 'supports OpenAPI 3.1.0 version' do
      result = GrapeSwagger::OpenAPI::VersionSelector.build_spec(openapi_version: '3.1.0')

      expect(result.openapi_3_1_0?).to be true
      expect(result.swagger_2_0?).to be false
    end
  end

  describe 'type mapping compatibility' do
    it 'maps integer correctly for Swagger 2.0' do
      result = GrapeSwagger::OpenAPI::TypeMapper.map('integer', version_2_0)

      expect(result[:type]).to eq('integer')
    end

    it 'maps integer correctly for OpenAPI 3.1.0' do
      result = GrapeSwagger::OpenAPI::TypeMapper.map('integer', version_3_1)

      expect(result[:type]).to eq('integer')
    end

    it 'maps string correctly for both versions' do
      swagger_result = GrapeSwagger::OpenAPI::TypeMapper.map('string', version_2_0)
      openapi_result = GrapeSwagger::OpenAPI::TypeMapper.map('string', version_3_1)

      expect(swagger_result[:type]).to eq('string')
      expect(openapi_result[:type]).to eq('string')
    end

    it 'maps boolean correctly for both versions' do
      swagger_result = GrapeSwagger::OpenAPI::TypeMapper.map('boolean', version_2_0)
      openapi_result = GrapeSwagger::OpenAPI::TypeMapper.map('boolean', version_3_1)

      expect(swagger_result[:type]).to eq('boolean')
      expect(openapi_result[:type]).to eq('boolean')
    end
  end

  describe 'nullable handling' do
    it 'transforms nullable to type array for OpenAPI 3.1.0' do
      schema = { type: 'string', nullable: true }

      result = GrapeSwagger::OpenAPI::NullableTypeHandler.transform(schema, version_3_1)

      expect(result[:type]).to eq(%w[string null])
      expect(result).not_to have_key(:nullable)
    end

    it 'preserves nullable as-is for Swagger 2.0' do
      schema = { type: 'string', nullable: true }

      result = GrapeSwagger::OpenAPI::NullableTypeHandler.transform(schema, version_2_0)

      expect(result[:nullable]).to be true
    end
  end

  describe 'binary data handling' do
    it 'uses contentEncoding for OpenAPI 3.1.0' do
      schema = { type: 'string', format: 'binary' }

      result = GrapeSwagger::OpenAPI::BinaryDataEncoder.encode(schema, version_3_1)

      expect(result[:contentEncoding]).to eq('base64')
      expect(result[:contentMediaType]).to eq('application/octet-stream')
    end

    it 'preserves format for Swagger 2.0' do
      schema = { type: 'string', format: 'binary' }

      result = GrapeSwagger::OpenAPI::BinaryDataEncoder.encode(schema, version_2_0)

      expect(result[:format]).to eq('binary')
    end
  end

  describe 'security scheme compatibility' do
    it 'builds API key scheme for both versions' do
      config = { type: 'apiKey', name: 'X-API-Key', in: 'header' }

      swagger_result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_2_0)
      openapi_result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

      expect(swagger_result[:type]).to eq('apiKey')
      expect(openapi_result[:type]).to eq('apiKey')
    end

    it 'builds OAuth2 scheme for both versions' do
      config = {
        type: 'oauth2',
        flows: {
          authorizationCode: {
            authorization_url: 'https://auth.example.com/authorize',
            token_url: 'https://auth.example.com/token',
            scopes: { 'read' => 'Read access' }
          }
        }
      }

      swagger_result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_2_0)
      openapi_result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

      expect(swagger_result[:type]).to eq('oauth2')
      expect(openapi_result[:type]).to eq('oauth2')
    end

    it 'returns nil for OpenID Connect in Swagger 2.0' do
      config = { type: 'openIdConnect', openid_connect_url: 'https://example.com' }

      result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_2_0)

      expect(result).to be_nil
    end

    it 'builds OpenID Connect for OpenAPI 3.1.0' do
      config = { type: 'openIdConnect', openid_connect_url: 'https://example.com' }

      result = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config, version_3_1)

      expect(result[:type]).to eq('openIdConnect')
    end
  end

  describe 'polymorphic schema compatibility' do
    it 'returns nil for oneOf in Swagger 2.0' do
      result = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_one_of(
        %w[A B], nil, version_2_0
      )

      expect(result).to be_nil
    end

    it 'builds oneOf for OpenAPI 3.1.0' do
      result = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_one_of(
        %w[A B], nil, version_3_1
      )

      expect(result[:oneOf]).to be_an(Array)
    end

    it 'builds allOf for both versions' do
      result_2_0 = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_all_of(
        'Base', { type: 'object' }, version_2_0
      )
      result_3_1 = GrapeSwagger::OpenAPI::PolymorphicSchemaBuilder.build_all_of(
        'Base', { type: 'object' }, version_3_1
      )

      expect(result_2_0[:allOf]).to be_an(Array)
      expect(result_3_1[:allOf]).to be_an(Array)
    end
  end

  describe 'discriminator compatibility' do
    it 'returns simple string for Swagger 2.0' do
      config = { property_name: 'type', mapping: { 'a' => 'A' } }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config, version_2_0)

      expect(result).to eq('type')
    end

    it 'returns full object for OpenAPI 3.1.0' do
      config = { property_name: 'type', mapping: { 'a' => 'A' } }

      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(config, version_3_1)

      expect(result).to be_a(Hash)
      expect(result[:propertyName]).to eq('type')
      expect(result[:mapping]).to be_a(Hash)
    end
  end

  describe 'version detection' do
    it 'correctly identifies version 2.0' do
      version = GrapeSwagger::OpenAPI::Version.new('2.0')

      expect(version.swagger_2_0?).to be true
      expect(version.openapi_3_1_0?).to be false
      expect(version.version_string).to eq('2.0')
    end

    it 'correctly identifies version 3.1.0' do
      version = GrapeSwagger::OpenAPI::Version.new('3.1.0')

      expect(version.swagger_2_0?).to be false
      expect(version.openapi_3_1_0?).to be true
      expect(version.version_string).to eq('3.1.0')
    end
  end

  describe 'all builders handle nil input' do
    it 'TypeMapper handles nil' do
      result = GrapeSwagger::OpenAPI::TypeMapper.map(nil, version_3_1)

      expect(result).to be_a(Hash)
    end

    it 'NullableTypeHandler handles nil schema' do
      result = GrapeSwagger::OpenAPI::NullableTypeHandler.transform(nil, version_3_1)

      expect(result).to be_nil
    end

    it 'DiscriminatorBuilder handles nil' do
      result = GrapeSwagger::OpenAPI::DiscriminatorBuilder.build(nil, version_3_1)

      expect(result).to be_nil
    end

    it 'WebhookBuilder handles nil' do
      result = GrapeSwagger::OpenAPI::WebhookBuilder.build(nil, version_3_1)

      expect(result).to be_nil
    end

    it 'WebhookBuilder handles empty hash' do
      result = GrapeSwagger::OpenAPI::WebhookBuilder.build({}, version_3_1)

      expect(result).to be_nil
    end
  end
end
