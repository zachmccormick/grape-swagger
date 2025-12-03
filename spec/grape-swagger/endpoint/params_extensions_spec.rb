# frozen_string_literal: true

require 'spec_helper'

describe 'Parameter reference DSL' do
  before(:all) do
    # Define reusable parameter as a constant
    unless defined?(RefTestPageParam)
      Object.const_set(:RefTestPageParam, Class.new(GrapeSwagger::ReusableParameter) do
        name 'page'
        in_query
        schema type: 'integer', default: 1
        description 'Page number'
      end)
    end
  end

  before(:each) do
    GrapeSwagger::ComponentsRegistry.reset!
    # Re-register after reset
    GrapeSwagger::ComponentsRegistry.register_parameter(RefTestPageParam)
  end

  let(:app) do
    Class.new(Grape::API) do
      format :json

      desc 'List items'
      params do
        ref :RefTestPageParam
        optional :filter, type: String, desc: 'Filter string'
      end
      get '/items' do
        { page: params[:page], filter: params[:filter] }
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  it 'generates $ref for referenced parameter' do
    parameters = subject['paths']['/items']['get']['parameters']

    ref_param = parameters.find { |p| p['$ref'] }
    expect(ref_param).not_to be_nil
    expect(ref_param['$ref']).to eq('#/components/parameters/RefTestPageParam')
  end

  it 'still includes inline parameters' do
    parameters = subject['paths']['/items']['get']['parameters']

    filter_param = parameters.find { |p| p['name'] == 'filter' }
    expect(filter_param).not_to be_nil
    expect(filter_param['in']).to eq('query')
  end

  it 'includes referenced parameter in components' do
    expect(subject['components']['parameters']).to have_key('RefTestPageParam')
    expect(subject['components']['parameters']['RefTestPageParam']['name']).to eq('page')
  end
end
