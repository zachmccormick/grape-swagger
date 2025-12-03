# frozen_string_literal: true

module V1
  # Demonstrates OpenAPI 3.1.0 parameter features
  class ParametersDemoAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :parameters do
      # ============================================
      # Cookie Parameters (OpenAPI 3.1.0 feature)
      # ============================================
      desc 'Demonstrates cookie parameters',
           summary: 'Get session info using cookie authentication',
           detail: <<~DESC,
             This endpoint demonstrates the use of cookie parameters in OpenAPI 3.1.0.

             Cookie parameters are defined with `in: 'cookie'` and are useful for:
             - Session tokens
             - CSRF tokens
             - User preferences stored in cookies
           DESC
           success: { code: 200, message: 'Session info retrieved' },
           failure: [
             { code: 401, message: 'Invalid session' },
             { code: 'default', message: 'Unexpected error' }
           ],
           tags: ['parameters']
      params do
        requires :session_id, type: String, documentation: { in: 'cookie' }, desc: 'Session identifier cookie'
        optional :csrf_token, type: String, documentation: { in: 'cookie' }, desc: 'CSRF protection token'
        optional :preferences, type: String, documentation: { in: 'cookie', deprecated: true },
                               desc: 'User preferences (deprecated - use user settings API instead)'
      end
      get 'cookie-session' do
        {
          session_id: params[:session_id],
          user_id: 123,
          expires_at: Time.now + 3600,
          preferences: params[:preferences]
        }
      end

      # ============================================
      # Deprecated Parameters
      # ============================================
      desc 'Demonstrates deprecated parameters',
           summary: 'Search with legacy and modern parameters',
           detail: <<~DESC,
             This endpoint shows how to mark specific parameters as deprecated
             while introducing their replacements.

             The `q` parameter is deprecated in favor of `query`.
             The `limit` parameter is deprecated in favor of `page_size`.
           DESC
           success: { code: 200, message: 'Search results' },
           tags: ['parameters']
      params do
        optional :query, type: String, desc: 'Search query (preferred)'
        optional :q, type: String, documentation: { deprecated: true },
                     desc: 'Search query (DEPRECATED - use `query` instead)'
        optional :page_size, type: Integer, default: 20, desc: 'Results per page (preferred)'
        optional :limit, type: Integer, documentation: { deprecated: true },
                         desc: 'Results per page (DEPRECATED - use `page_size` instead)'
      end
      get 'deprecated-search' do
        search_query = params[:query] || params[:q]
        size = params[:page_size] || params[:limit] || 20
        {
          query: search_query,
          page_size: size,
          results: []
        }
      end

      # ============================================
      # Parameter content field (complex serialization)
      # ============================================
      desc 'Demonstrates parameter content field for complex serialization',
           summary: 'Search with JSON filter in query string',
           detail: <<~DESC,
             This endpoint demonstrates the `content` field in Parameter Object.
             When you need to pass complex data (like JSON) in a query parameter,
             use `content` instead of `schema` to specify the media type and schema.
           DESC
           success: { code: 200, message: 'Filtered results' },
           tags: ['parameters']
      params do
        optional :filter, type: String, documentation: {
          desc: 'JSON filter object for complex queries',
          content: {
            'application/json' => {
              schema: {
                type: 'object',
                properties: {
                  field: { type: 'string', description: 'Field to filter on' },
                  operator: { type: 'string', enum: %w[eq ne gt lt contains], description: 'Comparison operator' },
                  value: { type: 'string', description: 'Value to compare against' }
                },
                required: %w[field operator value]
              },
              example: { field: 'status', operator: 'eq', value: 'active' }
            }
          }
        }
      end
      get 'complex-filter' do
        filter = params[:filter] ? JSON.parse(params[:filter]) : {}
        {
          filter_applied: filter,
          results: [
            { id: 1, name: 'Matching Item 1' },
            { id: 2, name: 'Matching Item 2' }
          ]
        }
      end

      # ============================================
      # Reference summary/description overrides
      # ============================================
      desc 'Demonstrates reference overrides for context-specific docs',
           summary: 'List users with context-specific parameter docs',
           detail: <<~DESC,
             This endpoint demonstrates OpenAPI 3.1.0 Reference Object overrides.
             When referencing a reusable parameter, you can override its summary
             and description for context-specific documentation.

             The `page` parameter references a shared component but has a
             custom description specific to the users list context.
           DESC
           success: { code: 200, message: 'List of users' },
           tags: ['parameters']
      params do
        optional :page, type: Integer, documentation: {
          ref: API.parameter_ref(:PageParam),
          ref_summary: 'User list page',
          ref_description: 'Page number for the user listing. User lists are sorted by registration date.'
        }
        optional :role, type: String, documentation: {
          ref: API.parameter_ref(:FilterParam),
          ref_description: 'Filter users by role (admin, member, guest)'
        }
      end
      get 'ref-overrides' do
        {
          users: [
            { id: 1, name: 'Admin User', role: 'admin' },
            { id: 2, name: 'Regular User', role: 'member' }
          ],
          page: params[:page] || 1
        }
      end

      # ============================================
      # Parameter externalDocs Demo
      # ============================================
      desc 'Demonstrates parameter-level external documentation',
           summary: 'Query with documented filter syntax',
           detail: <<~DESC,
             This endpoint shows how individual parameters can have external documentation
             links for detailed syntax or usage guides.
           DESC
           success: { code: 200, message: 'Query results' },
           tags: ['parameters']
      params do
        optional :query, type: String, documentation: {
          desc: 'Query using our custom query language (see external docs)',
          external_docs: {
            description: 'Query Language Reference',
            url: 'https://example.com/docs/query-language'
          }
        }
        optional :sort, type: String, documentation: {
          desc: 'Sort expression (field:direction)',
          external_docs: {
            description: 'Sorting Guide',
            url: 'https://example.com/docs/sorting'
          }
        }
      end
      get 'external-docs' do
        { query: params[:query], sort: params[:sort], results: [] }
      end

      # ============================================
      # Parameter Examples (multiple named examples)
      # ============================================
      desc 'Demonstrates parameter with multiple named examples',
           summary: 'List items with example filter values',
           detail: <<~DESC,
             This endpoint demonstrates multiple named examples for parameters.
             Each example has a summary, description, and value.
           DESC
           success: { code: 200, message: 'Filtered items' },
           tags: ['parameters']
      params do
        optional :status, type: String, documentation: {
          desc: 'Filter by status',
          examples: {
            active: {
              summary: 'Active items',
              description: 'Show only active items',
              value: 'active'
            },
            inactive: {
              summary: 'Inactive items',
              description: 'Show only inactive items',
              value: 'inactive'
            },
            pending: {
              summary: 'Pending items',
              description: 'Show items awaiting approval',
              value: 'pending'
            }
          }
        }
      end
      get 'with-examples' do
        { status: params[:status], items: [] }
      end
    end
  end
end
