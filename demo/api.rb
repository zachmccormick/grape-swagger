# frozen_string_literal: true

require 'grape'
require 'grape-swagger'

class DemoAPI < Grape::API
  format :json

  desc 'Health check'
  get :status do
    { status: 'ok' }
  end

  add_swagger_documentation(
    openapi_version: '3.1.0',
    info: {
      title: 'Demo API',
      description: 'Progressive demo for OpenAPI 3.1.0 features',
      version: '1.0.0'
    }
  )
end
