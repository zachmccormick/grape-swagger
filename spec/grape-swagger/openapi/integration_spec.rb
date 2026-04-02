# frozen_string_literal: true

require 'spec_helper'

describe 'Version Management System Integration' do
  describe 'module accessibility' do
    it 'exposes VersionSelector from GrapeSwagger::OpenAPI' do
      expect(GrapeSwagger::OpenAPI::VersionSelector).to be_a(Class)
    end

    it 'exposes Version from GrapeSwagger::OpenAPI' do
      expect(GrapeSwagger::OpenAPI::Version).to be_a(Class)
    end

    it 'exposes VersionConstants from GrapeSwagger::OpenAPI' do
      expect(GrapeSwagger::OpenAPI::VersionConstants).to be_a(Module)
    end

    it 'exposes UnsupportedVersionError from GrapeSwagger::OpenAPI::Errors' do
      expect(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError).to be < StandardError
    end
  end

  describe 'complete workflow' do
    it 'defaults to Swagger 2.0 when no version specified' do
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec({})
      expect(version.version_string).to eq('2.0')
      expect(version.swagger_2_0?).to be true
      expect(version.openapi_3_1_0?).to be false
    end

    it 'selects OpenAPI 3.1.0 when specified' do
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(openapi_version: '3.1.0')
      expect(version.version_string).to eq('3.1.0')
      expect(version.openapi_3_1_0?).to be true
      expect(version.swagger_2_0?).to be false
    end

    it 'respects backward compatibility with swagger_version' do
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(swagger_version: '2.0')
      expect(version.version_string).to eq('2.0')
    end

    it 'prioritizes openapi_version over swagger_version' do
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(
        openapi_version: '3.1.0',
        swagger_version: '2.0'
      )
      expect(version.openapi_3_1_0?).to be true
    end

    it 'rejects unsupported versions with helpful error' do
      expect do
        GrapeSwagger::OpenAPI::VersionSelector.build_spec(openapi_version: '4.0.0')
      end.to raise_error(
        GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError,
        /4\.0\.0.*2\.0.*3\.1\.0/
      )
    end

    it 'preserves options on the version object' do
      options = { openapi_version: '3.1.0', info: { title: 'My API' } }
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(options)
      expect(version.options[:info]).to eq(title: 'My API')
    end
  end
end
