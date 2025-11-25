# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::VersionSelector do
  describe '.detect_version' do
    context 'when openapi_version is specified' do
      it 'returns the specified openapi_version' do
        options = { openapi_version: '3.1.0' }
        expect(described_class.detect_version(options)).to eq('3.1.0')
      end

      it 'returns the specified openapi_version as string when symbol key' do
        options = { openapi_version: '3.1.0' }
        expect(described_class.detect_version(options)).to eq('3.1.0')
      end
    end

    context 'when swagger_version is specified' do
      it 'returns swagger_version for backward compatibility' do
        options = { swagger_version: '2.0' }
        expect(described_class.detect_version(options)).to eq('2.0')
      end
    end

    context 'when no version is specified' do
      it 'defaults to Swagger 2.0' do
        options = {}
        expect(described_class.detect_version(options)).to eq('2.0')
      end
    end

    context 'when both openapi_version and swagger_version are specified' do
      it 'prioritizes openapi_version over swagger_version' do
        options = { openapi_version: '3.1.0', swagger_version: '2.0' }
        expect(described_class.detect_version(options)).to eq('3.1.0')
      end
    end
  end

  describe '.validate_version' do
    context 'with supported versions' do
      it 'validates 2.0 as supported' do
        expect { described_class.validate_version('2.0') }.not_to raise_error
      end

      it 'validates 3.1.0 as supported' do
        expect { described_class.validate_version('3.1.0') }.not_to raise_error
      end
    end

    context 'with unsupported versions' do
      it 'raises UnsupportedVersionError for invalid version' do
        expect { described_class.validate_version('1.0') }
          .to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
      end

      it 'raises UnsupportedVersionError for nil version' do
        expect { described_class.validate_version(nil) }
          .to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
      end

      it 'includes helpful error message with supported versions' do
        error = nil
        begin
          described_class.validate_version('4.0.0')
        rescue GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError => e
          error = e
        end
        expect(error.message).to include('2.0', '3.1.0')
      end
    end
  end

  describe '.supported_versions' do
    it 'returns list of supported versions' do
      versions = described_class.supported_versions
      expect(versions).to include('2.0', '3.1.0')
    end

    it 'returns versions as an array' do
      expect(described_class.supported_versions).to be_an(Array)
    end
  end

  describe '.build_spec' do
    context 'with Swagger 2.0' do
      it 'returns a version object configured for 2.0' do
        options = { swagger_version: '2.0' }
        spec = described_class.build_spec(options)
        expect(spec).to be_a(GrapeSwagger::OpenAPI::Version)
        expect(spec.version_string).to eq('2.0')
      end
    end

    context 'with OpenAPI 3.1.0' do
      it 'returns a version object configured for 3.1.0' do
        options = { openapi_version: '3.1.0' }
        spec = described_class.build_spec(options)
        expect(spec).to be_a(GrapeSwagger::OpenAPI::Version)
        expect(spec.version_string).to eq('3.1.0')
      end
    end

    context 'with default (no version specified)' do
      it 'returns a version object for Swagger 2.0' do
        options = {}
        spec = described_class.build_spec(options)
        expect(spec).to be_a(GrapeSwagger::OpenAPI::Version)
        expect(spec.version_string).to eq('2.0')
      end
    end

    context 'with unsupported version' do
      it 'raises UnsupportedVersionError' do
        options = { openapi_version: '4.0.0' }
        expect { described_class.build_spec(options) }
          .to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
      end
    end

    it 'passes options through to the version object' do
      options = { openapi_version: '3.1.0', info: { title: 'Test API' } }
      spec = described_class.build_spec(options)
      expect(spec.options).to eq(options)
    end
  end
end
