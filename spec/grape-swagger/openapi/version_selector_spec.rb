# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::VersionSelector do
  describe '.detect_version' do
    context 'when openapi_version is specified' do
      it 'returns the specified openapi_version' do
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
        expect(described_class.detect_version({})).to eq('2.0')
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
    it 'accepts 2.0' do
      expect { described_class.validate_version('2.0') }.not_to raise_error
    end

    it 'accepts 3.1.0' do
      expect { described_class.validate_version('3.1.0') }.not_to raise_error
    end

    it 'raises UnsupportedVersionError for invalid version' do
      expect { described_class.validate_version('1.0') }
        .to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
    end

    it 'raises UnsupportedVersionError for nil version' do
      expect { described_class.validate_version(nil) }
        .to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
    end

    it 'includes supported versions in error message' do
      expect { described_class.validate_version('4.0.0') }
        .to raise_error(/2\.0.*3\.1\.0/)
    end
  end

  describe '.supported_versions' do
    it 'returns an array containing 2.0 and 3.1.0' do
      versions = described_class.supported_versions
      expect(versions).to contain_exactly('2.0', '3.1.0')
    end
  end

  describe '.build_spec' do
    it 'returns a Version object for Swagger 2.0 by default' do
      spec = described_class.build_spec({})
      expect(spec).to be_a(GrapeSwagger::OpenAPI::Version)
      expect(spec.version_string).to eq('2.0')
      expect(spec.swagger_2_0?).to be true
    end

    it 'returns a Version object for OpenAPI 3.1.0 when specified' do
      spec = described_class.build_spec(openapi_version: '3.1.0')
      expect(spec.version_string).to eq('3.1.0')
      expect(spec.openapi_3_1_0?).to be true
    end

    it 'raises UnsupportedVersionError for invalid version' do
      expect { described_class.build_spec(openapi_version: '4.0.0') }
        .to raise_error(GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError)
    end

    it 'passes options through to the version object' do
      options = { openapi_version: '3.1.0', info: { title: 'Test API' } }
      spec = described_class.build_spec(options)
      expect(spec.options).to eq(options)
    end
  end
end
