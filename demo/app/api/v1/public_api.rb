# frozen_string_literal: true

module V1
  # Public API endpoints - no authentication required
  # Demonstrates: security: [] to override global security
  class PublicAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :public do
      desc 'Health check endpoint',
           summary: 'Check API health status',
           detail: 'Returns the current health status of the API. No authentication required.',
           security: [], # Override global security - this is a public endpoint
           success: {
             code: 200,
             message: 'API is healthy',
             examples: {
               'application/json' => {
                 status: 'healthy',
                 version: '1.0.0',
                 timestamp: '2024-01-15T12:00:00Z',
                 services: {
                   database: 'connected',
                   cache: 'connected',
                   queue: 'connected'
                 }
               }
             }
           },
           tags: ['public']
      get 'health' do
        {
          status: 'healthy',
          version: '1.0.0',
          timestamp: Time.now.iso8601,
          services: {
            database: 'connected',
            cache: 'connected',
            queue: 'connected'
          }
        }
      end

      desc 'API information',
           summary: 'Get API metadata',
           detail: 'Returns information about the API including version and documentation links.',
           security: [], # Public endpoint
           success: {
             code: 200,
             message: 'API information',
             examples: {
               'application/json' => {
                 name: 'Demo API',
                 version: '1.0.0',
                 openapi_version: '3.1.0',
                 documentation_url: '/swagger_doc',
                 support_email: 'api-support@example.com'
               }
             }
           },
           tags: ['public']
      get 'info' do
        {
          name: 'Demo API',
          version: '1.0.0',
          openapi_version: '3.1.0',
          documentation_url: '/swagger_doc',
          support_email: 'api-support@example.com'
        }
      end

      desc 'List available API versions',
           summary: 'Get supported API versions',
           security: [], # Public endpoint
           is_array: true,
           success: {
             code: 200,
             examples: {
               'application/json' => [
                 { version: 'v1', status: 'current', deprecated: false },
                 { version: 'v2', status: 'beta', deprecated: false }
               ]
             }
           },
           tags: ['public']
      get 'versions' do
        [
          { version: 'v1', status: 'current', deprecated: false, sunset_date: nil },
          { version: 'v2', status: 'beta', deprecated: false, sunset_date: nil }
        ]
      end

      desc 'Validate email format',
           summary: 'Check if email is valid',
           detail: 'Validates an email address format without creating an account.',
           security: [], # Public endpoint
           success: {
             code: 200,
             examples: {
               'application/json' => { valid: true, email: 'user@example.com', suggestions: [] }
             }
           },
           failure: [
             { code: 400, message: 'Invalid email format',
               examples: { 'application/json' => { valid: false, error: 'Invalid email format' } } }
           ],
           tags: ['public']
      params do
        requires :email, type: String,
                         regexp: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/,
                         desc: 'Email address to validate (must match standard email pattern)'
      end
      post 'validate-email' do
        { valid: true, email: params[:email], suggestions: [] }
      end
    end
  end
end
