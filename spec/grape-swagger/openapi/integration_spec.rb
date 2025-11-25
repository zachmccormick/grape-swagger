# frozen_string_literal: true

require 'spec_helper'

describe 'Version Management System Integration' do
  describe 'VersionSelector module availability' do
    it 'is accessible from GrapeSwagger namespace' do
      expect(GrapeSwagger::OpenAPI::VersionSelector).to be_a(Class)
    end

    it 'provides all required class methods' do
      expect(GrapeSwagger::OpenAPI::VersionSelector).to respond_to(:detect_version)
      expect(GrapeSwagger::OpenAPI::VersionSelector).to respond_to(:validate_version)
      expect(GrapeSwagger::OpenAPI::VersionSelector).to respond_to(:supported_versions)
      expect(GrapeSwagger::OpenAPI::VersionSelector).to respond_to(:build_spec)
    end
  end

  describe 'Version class availability' do
    it 'is accessible from GrapeSwagger::OpenAPI namespace' do
      expect(GrapeSwagger::OpenAPI::Version).to be_a(Class)
    end

    it 'can be instantiated' do
      version = GrapeSwagger::OpenAPI::Version.new('2.0')
      expect(version).to be_a(GrapeSwagger::OpenAPI::Version)
    end
  end

  describe 'VersionConstants module availability' do
    it 'is accessible from GrapeSwagger::OpenAPI namespace' do
      expect(GrapeSwagger::OpenAPI::VersionConstants).to be_a(Module)
    end

    it 'provides version constants' do
      expect(GrapeSwagger::OpenAPI::VersionConstants::SWAGGER_2_0).to eq('2.0')
      expect(GrapeSwagger::OpenAPI::VersionConstants::OPENAPI_3_1_0).to eq('3.1.0')
      expect(GrapeSwagger::OpenAPI::VersionConstants::SUPPORTED_VERSIONS).to eq(['2.0', '3.1.0'])
    end
  end

  describe 'Error handling' do
    it 'provides UnsupportedVersionError' do
      expect(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError).to be < StandardError
    end

    it 'can be raised and caught' do
      expect do
        raise GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError.new('4.0.0', ['2.0', '3.1.0'])
      end.to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
    end
  end

  describe 'Complete workflow' do
    it 'detects default version, validates it, and builds spec' do
      options = {}
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(options)
      expect(version.version_string).to eq('2.0')
      expect(version.swagger_2_0?).to be true
    end

    it 'detects custom version, validates it, and builds spec' do
      options = { openapi_version: '3.1.0' }
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(options)
      expect(version.version_string).to eq('3.1.0')
      expect(version.openapi_3_1_0?).to be true
    end

    it 'respects backward compatibility with swagger_version' do
      options = { swagger_version: '2.0' }
      version = GrapeSwagger::OpenAPI::VersionSelector.build_spec(options)
      expect(version.version_string).to eq('2.0')
    end
  end
end
