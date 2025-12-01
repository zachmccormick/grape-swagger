# frozen_string_literal: true

require 'spec_helper'

describe 'Reusable Components Integration' do
  # Define reusable components
  before(:all) do
    GrapeSwagger::ComponentsRegistry.reset!
    # Parameters
    page_param = Class.new(GrapeSwagger::ReusableParameter) do
      name 'page'
      in_query
      schema type: 'integer', default: 1, minimum: 1
      description 'Page number for pagination'
    end
    Object.const_set(:IntegrationPageParam, page_param)
    # Re-register after const_set so the name is available
    GrapeSwagger::ComponentsRegistry.register_parameter(page_param)

    per_page_param = Class.new(GrapeSwagger::ReusableParameter) do
      name 'per_page'
      in_query
      schema type: 'integer', default: 20, minimum: 1, maximum: 100
      description 'Items per page'
    end
    Object.const_set(:IntegrationPerPageParam, per_page_param)
    GrapeSwagger::ComponentsRegistry.register_parameter(per_page_param)

    # Responses
    not_found_response = Class.new(GrapeSwagger::ReusableResponse) do
      description 'The requested resource was not found'
      json_schema({ type: 'object', properties: { error: { type: 'string' }, code: { type: 'integer' } } })
    end
    Object.const_set(:IntegrationNotFoundResponse, not_found_response)
    GrapeSwagger::ComponentsRegistry.register_response(not_found_response)

    unauthorized_response = Class.new(GrapeSwagger::ReusableResponse) do
      description 'Authentication is required'
      json_schema({ type: 'object', properties: { message: { type: 'string' } } })
    end
    Object.const_set(:IntegrationUnauthorizedResponse, unauthorized_response)
    GrapeSwagger::ComponentsRegistry.register_response(unauthorized_response)

    # Headers
    rate_limit_header = Class.new(GrapeSwagger::ReusableHeader) do
      description 'Number of API requests remaining in current window'
      schema type: 'integer'
      example 99
    end
    Object.const_set(:IntegrationRateLimitHeader, rate_limit_header)
    GrapeSwagger::ComponentsRegistry.register_header(rate_limit_header)
  end

  let(:app) do
    Class.new(Grape::API) do
      format :json

      resource :users do
        desc 'List all users',
             success: { code: 200, message: 'Success' },
             failure: [
               { code: 401, model: :IntegrationUnauthorizedResponse }
             ]
        params do
          ref :IntegrationPageParam
          ref :IntegrationPerPageParam
          optional :status, type: String, values: %w[active inactive], desc: 'Filter by status'
        end
        get do
          { users: [], page: params[:page], per_page: params[:per_page] }
        end

        desc 'Get a specific user',
             success: { code: 200, message: 'Success' },
             failure: [
               { code: 404, model: :IntegrationNotFoundResponse },
               { code: 401, model: :IntegrationUnauthorizedResponse }
             ]
        params do
          requires :id, type: Integer, desc: 'User ID'
        end
        get ':id' do
          { id: params[:id] }
        end
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'components section' do
    it 'includes all registered parameters' do
      params = subject['components']['parameters']

      expect(params).to have_key('IntegrationPageParam')
      expect(params).to have_key('IntegrationPerPageParam')
      expect(params['IntegrationPageParam']['name']).to eq('page')
      expect(params['IntegrationPageParam']['in']).to eq('query')
      expect(params['IntegrationPageParam']['schema']['type']).to eq('integer')
    end

    it 'includes all registered responses' do
      responses = subject['components']['responses']

      expect(responses).to have_key('IntegrationNotFoundResponse')
      expect(responses).to have_key('IntegrationUnauthorizedResponse')
      expect(responses['IntegrationNotFoundResponse']['description']).to eq('The requested resource was not found')
    end

    it 'includes all registered headers' do
      headers = subject['components']['headers']

      expect(headers).to have_key('IntegrationRateLimitHeader')
      expect(headers['IntegrationRateLimitHeader']['schema']['type']).to eq('integer')
    end
  end

  describe 'parameter references' do
    it 'generates $ref for referenced parameters in list endpoint' do
      params = subject['paths']['/users']['get']['parameters']
      refs = params.select { |p| p['$ref'] }

      expect(refs.length).to eq(2)
      expect(refs.map { |r| r['$ref'] }).to include(
        '#/components/parameters/IntegrationPageParam',
        '#/components/parameters/IntegrationPerPageParam'
      )
    end

    it 'still includes inline parameters alongside refs' do
      params = subject['paths']['/users']['get']['parameters']
      status_param = params.find { |p| p['name'] == 'status' }

      expect(status_param).not_to be_nil
      expect(status_param['in']).to eq('query')
    end
  end

  describe 'response references' do
    it 'generates $ref for error responses' do
      responses = subject['paths']['/users/{id}']['get']['responses']

      expect(responses['404']).to eq({ '$ref' => '#/components/responses/IntegrationNotFoundResponse' })
      expect(responses['401']).to eq({ '$ref' => '#/components/responses/IntegrationUnauthorizedResponse' })
    end

    it 'reuses same response reference across endpoints' do
      list_responses = subject['paths']['/users']['get']['responses']
      get_responses = subject['paths']['/users/{id}']['get']['responses']

      expect(list_responses['401']).to eq(get_responses['401'])
    end
  end

  describe 'runtime behavior' do
    it 'applies default values from referenced parameters' do
      get '/users'
      response = JSON.parse(last_response.body)

      expect(response['page']).to eq(1)
      expect(response['per_page']).to eq(20)
    end

    it 'accepts custom values for referenced parameters' do
      get '/users', page: 5, per_page: 50
      response = JSON.parse(last_response.body)

      expect(response['page']).to eq(5)
      expect(response['per_page']).to eq(50)
    end
  end
end
