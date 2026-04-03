# frozen_string_literal: true

require 'spec_helper'

describe 'Wildcard Status Codes (OpenAPI 3.1.0)' do
  # ============================================
  # Basic Wildcard Responses (4XX, 5XX)
  # ============================================
  describe 'basic wildcard responses' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Get items with wildcard error responses',
             success: { code: 200, message: 'OK' },
             failure: [
               { code: '4XX', message: 'Client Error' },
               { code: '5XX', message: 'Server Error' }
             ]
        get '/items' do
          []
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes 4XX wildcard response' do
      responses = subject['paths']['/items']['get']['responses']
      expect(responses).to have_key('4XX')
      expect(responses['4XX']['description']).to eq('Client Error')
    end

    it 'includes 5XX wildcard response' do
      responses = subject['paths']['/items']['get']['responses']
      expect(responses).to have_key('5XX')
      expect(responses['5XX']['description']).to eq('Server Error')
    end

    it 'includes the success response' do
      responses = subject['paths']['/items']['get']['responses']
      expect(responses).to have_key('200')
      expect(responses['200']['description']).to eq('OK')
    end
  end

  # ============================================
  # Mixed Specific and Wildcard Responses
  # ============================================
  describe 'mixed specific and wildcard responses' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with specific and wildcard responses',
             success: { code: 200, message: 'Success' },
             failure: [
               { code: 400, message: 'Bad Request - Validation Error' },
               { code: 401, message: 'Unauthorized' },
               { code: 404, message: 'Not Found' },
               { code: '4XX', message: 'Other Client Errors' },
               { code: '5XX', message: 'Server Error' }
             ]
        params do
          requires :id, type: Integer
        end
        get '/resources/:id' do
          { id: params[:id] }
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes all specific 4xx responses' do
      responses = subject['paths']['/resources/{id}']['get']['responses']
      expect(responses).to have_key('400')
      expect(responses).to have_key('401')
      expect(responses).to have_key('404')
    end

    it 'includes 4XX wildcard for other client errors' do
      responses = subject['paths']['/resources/{id}']['get']['responses']
      expect(responses).to have_key('4XX')
      expect(responses['4XX']['description']).to eq('Other Client Errors')
    end

    it 'includes 5XX wildcard' do
      responses = subject['paths']['/resources/{id}']['get']['responses']
      expect(responses).to have_key('5XX')
    end
  end

  # ============================================
  # Wildcard Responses with Models
  # ============================================
  describe 'wildcard responses with models' do
    let(:error_entity) do
      Class.new(Grape::Entity) do
        expose :error_code, documentation: { type: String, desc: 'Error code' }
        expose :message, documentation: { type: String, desc: 'Error message' }
        expose :details, documentation: { type: Object, desc: 'Additional details' }
      end
    end

    def app
      error_model = error_entity
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with wildcard error model',
             success: { code: 200, message: 'Success' },
             failure: [
               { code: '4XX', message: 'Client Error', model: error_model },
               { code: '5XX', message: 'Server Error', model: error_model }
             ]
        get '/with-error-model' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes schema reference for 4XX response' do
      responses = subject['paths']['/with-error-model']['get']['responses']
      expect(responses['4XX']).to have_key('content')
      content = responses['4XX']['content']['application/json']
      expect(content).to have_key('schema')
    end

    it 'includes schema reference for 5XX response' do
      responses = subject['paths']['/with-error-model']['get']['responses']
      expect(responses['5XX']).to have_key('content')
      content = responses['5XX']['content']['application/json']
      expect(content).to have_key('schema')
    end
  end

  # ============================================
  # All Wildcard Codes (1XX through 5XX)
  # ============================================
  describe 'all wildcard codes' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with all wildcard types',
             success: { code: '2XX', message: 'Success' },
             failure: [
               { code: '1XX', message: 'Informational' },
               { code: '3XX', message: 'Redirection' },
               { code: '4XX', message: 'Client Error' },
               { code: '5XX', message: 'Server Error' }
             ]
        get '/all-wildcards' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes 1XX wildcard' do
      responses = subject['paths']['/all-wildcards']['get']['responses']
      expect(responses).to have_key('1XX')
    end

    it 'includes 2XX wildcard' do
      responses = subject['paths']['/all-wildcards']['get']['responses']
      expect(responses).to have_key('2XX')
    end

    it 'includes 3XX wildcard' do
      responses = subject['paths']['/all-wildcards']['get']['responses']
      expect(responses).to have_key('3XX')
    end

    it 'includes 4XX wildcard' do
      responses = subject['paths']['/all-wildcards']['get']['responses']
      expect(responses).to have_key('4XX')
    end

    it 'includes 5XX wildcard' do
      responses = subject['paths']['/all-wildcards']['get']['responses']
      expect(responses).to have_key('5XX')
    end
  end

  # ============================================
  # Default Response with Wildcards
  # ============================================
  describe 'default response with wildcards' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with default and wildcards',
             success: { code: 200, message: 'Success' },
             failure: [
               { code: '4XX', message: 'Client Error' },
               { code: 'default', message: 'Unexpected Error' }
             ]
        get '/with-default' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'includes both 4XX wildcard and default' do
      responses = subject['paths']['/with-default']['get']['responses']
      expect(responses).to have_key('4XX')
      expect(responses).to have_key('default')
    end

    it 'has correct descriptions' do
      responses = subject['paths']['/with-default']['get']['responses']
      expect(responses['4XX']['description']).to eq('Client Error')
      expect(responses['default']['description']).to eq('Unexpected Error')
    end
  end

  # ============================================
  # Lowercase Wildcards (case handling)
  # ============================================
  describe 'lowercase wildcards' do
    def app
      Class.new(Grape::API) do
        format :json

        desc 'Endpoint with lowercase wildcards',
             success: { code: 200, message: 'OK' },
             failure: [
               { code: '4xx', message: 'Client Error' },
               { code: '5xx', message: 'Server Error' }
             ]
        get '/lowercase-wildcards' do
          {}
        end

        add_swagger_documentation openapi_version: '3.1.0'
      end
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'accepts lowercase wildcard codes' do
      responses = subject['paths']['/lowercase-wildcards']['get']['responses']
      # The codes should be stored as provided (lowercase)
      expect(responses).to have_key('4xx')
      expect(responses).to have_key('5xx')
    end
  end
end
