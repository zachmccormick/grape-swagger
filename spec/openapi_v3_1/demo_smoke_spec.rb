# frozen_string_literal: true

require 'spec_helper'

# Minimal demo API for smoke testing OpenAPI 3.1.0 configuration
class DemoSmokeAPI < Grape::API
  format :json

  desc 'Health check'
  get :status do
    { status: 'ok' }
  end

  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'Demo API',
      description: 'Smoke test API',
      version: '1.0.0'
    }
  )
end

describe 'Demo API smoke test' do
  def app
    DemoSmokeAPI
  end

  it 'accepts openapi_version 3.1.0 without error' do
    expect { DemoSmokeAPI }.not_to raise_error
  end

  it 'still serves swagger doc endpoint' do
    get '/swagger_doc'
    expect(last_response.status).to eq(200)
  end
end
