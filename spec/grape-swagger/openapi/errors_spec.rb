# frozen_string_literal: true

require 'spec_helper'

describe GrapeSwagger::OpenAPI::Errors::UnsupportedVersionError do
  it 'is a StandardError' do
    expect(described_class).to be < StandardError
  end

  it 'includes the invalid version in the message' do
    error = described_class.new('4.0.0', ['2.0', '3.1.0'])
    expect(error.message).to include('4.0.0')
  end

  it 'includes supported versions in the message' do
    error = described_class.new('4.0.0', ['2.0', '3.1.0'])
    expect(error.message).to include('2.0')
    expect(error.message).to include('3.1.0')
  end

  it 'handles nil version gracefully' do
    error = described_class.new(nil, ['2.0', '3.1.0'])
    expect(error.message).to include('Unsupported OpenAPI version')
    expect(error.message).to include('2.0')
  end
end
