# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::VersionConstants do
  it 'defines SWAGGER_2_0 as 2.0' do
    expect(described_class::SWAGGER_2_0).to eq('2.0')
  end

  it 'defines OPENAPI_3_1_0 as 3.1.0' do
    expect(described_class::OPENAPI_3_1_0).to eq('3.1.0')
  end

  it 'defines SUPPORTED_VERSIONS containing both versions' do
    expect(described_class::SUPPORTED_VERSIONS).to contain_exactly('2.0', '3.1.0')
  end

  it 'freezes SUPPORTED_VERSIONS to prevent modification' do
    expect(described_class::SUPPORTED_VERSIONS).to be_frozen
  end
end
