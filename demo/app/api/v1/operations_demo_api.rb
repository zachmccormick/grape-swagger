# frozen_string_literal: true

module V1
  # Demonstrates OpenAPI 3.1.0 operation-level features
  class OperationsDemoAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :operations do
      # ============================================
      # External Documentation at Operation Level
      # ============================================
      desc 'Demonstrates operation-level external documentation',
           summary: 'Complex algorithm with external docs',
           detail: 'This operation has external documentation for detailed algorithm explanation.',
           external_docs: {
             description: 'Detailed algorithm documentation',
             url: 'https://example.com/docs/algorithms/scoring'
           },
           success: { code: 200, message: 'Score calculated' },
           tags: ['operations']
      params do
        requires :input, type: Float, desc: 'Input value for scoring'
      end
      post 'calculate-score' do
        {
          input: params[:input],
          score: (params[:input] * 0.85).round(2),
          algorithm_version: '2.3.1'
        }
      end

      # ============================================
      # Response Default Wildcard
      # ============================================
      desc 'Demonstrates default response wildcard',
           summary: 'Operation with default error response',
           detail: <<~DESC,
             This operation uses a `default` response to catch any unexpected errors.
             This is useful for documenting a standard error format for all non-specified
             status codes.
           DESC
           success: { code: 200, message: 'Operation successful' },
           failure: [
             { code: 400, message: 'Bad request - validation failed' },
             { code: 404, message: 'Resource not found' },
             { code: 'default', message: 'Unexpected error - see error response schema' }
           ],
           tags: ['operations']
      params do
        requires :id, type: Integer, desc: 'Resource ID'
      end
      get 'default-response/:id' do
        { id: params[:id], name: 'Sample Resource' }
      end

      # ============================================
      # Wildcard Status Codes (1XX, 2XX, 3XX, 4XX, 5XX)
      # ============================================
      desc 'Demonstrates wildcard status code responses',
           summary: 'Operation with wildcard status code ranges',
           detail: <<~DESC,
             This endpoint demonstrates OpenAPI 3.1.0 wildcard status codes:

             - **1XX**: Informational responses
             - **2XX**: Success responses (any 2xx code not explicitly defined)
             - **3XX**: Redirection responses
             - **4XX**: Client error responses
             - **5XX**: Server error responses
           DESC
           success: { code: 200, message: 'Specific success response' },
           http_codes: [
             { code: 201, message: 'Resource created' },
             { code: '1XX', message: 'Informational - processing continues' },
             { code: '2XX', message: 'Success - operation completed (generic)' },
             { code: '3XX', message: 'Redirection - see Location header' },
             { code: '4XX', message: 'Client error - check request parameters' },
             { code: '5XX', message: 'Server error - try again later' }
           ],
           tags: ['operations']
      params do
        requires :action, type: String, values: %w[create read redirect error], desc: 'Action to simulate'
      end
      post 'wildcard-responses' do
        case params[:action]
        when 'create'
          status 201
          { message: 'Created', id: rand(1000..9999) }
        when 'redirect'
          status 302
          header 'Location', 'https://example.com/new-location'
          { message: 'Redirecting' }
        when 'error'
          status 500
          { error: 'Simulated server error' }
        else
          { message: 'Success', action: params[:action] }
        end
      end

      # ============================================
      # Operation-level Servers
      # ============================================
      desc 'Demonstrates operation-level server override',
           summary: 'Operation with custom server configuration',
           detail: <<~DESC,
             This endpoint has its own server configuration that overrides the
             global and path-level servers.
           DESC
           servers: [
             {
               url: 'https://special-service.example.com/v2',
               description: 'Special processing server'
             },
             {
               url: 'https://backup.example.com/v2',
               description: 'Backup server for failover'
             }
           ],
           success: { code: 200, message: 'Processed on special server' },
           tags: ['operations']
      params do
        requires :data, type: String, desc: 'Data to process'
      end
      post 'custom-servers' do
        {
          data: params[:data],
          processed_by: 'special-service.example.com',
          timestamp: Time.now
        }
      end

      # ============================================
      # Component References (OpenAPI 3.1.0 feature)
      # ============================================
      desc 'Demonstrates reusable component references',
           summary: 'Get items with reusable parameters and responses',
           detail: <<~DESC,
             This endpoint demonstrates the use of $ref to reference reusable components:

             **Parameter References:** PageParam, LimitParam, SortParam
             **Response References:** UnauthorizedError, NotFoundError, InternalServerError
           DESC
           success: { code: 200, message: 'List of items' },
           failure: [
             { code: 401, '$ref' => API.response_ref(:UnauthorizedError) },
             { code: 404, '$ref' => API.response_ref(:NotFoundError) },
             { code: 500, '$ref' => API.response_ref(:InternalServerError) }
           ],
           tags: ['operations']
      params do
        optional :page, type: Integer, documentation: { ref: API.parameter_ref(:PageParam) }
        optional :limit, type: Integer, documentation: { ref: API.parameter_ref(:LimitParam) }
        optional :sort, type: String, documentation: { ref: API.parameter_ref(:SortParam) }
        optional :filter, type: String, desc: 'Filter expression (inline parameter)'
      end
      get 'component-refs' do
        {
          items: [
            { id: 1, name: 'Item 1' },
            { id: 2, name: 'Item 2' }
          ],
          pagination: {
            page: params[:page] || 1,
            limit: params[:limit] || 20,
            total: 100
          }
        }
      end
    end

    # ============================================
    # Path Item-level servers (applies to all operations on path)
    # ============================================
    resource :inventory do
      route_setting :path_servers, [
        { url: 'https://inventory.example.com/v1', description: 'Inventory service' },
        { url: 'https://warehouse.example.com/api', description: 'Warehouse backend' }
      ]

      desc 'List inventory items',
           summary: 'Get all inventory items',
           detail: <<~DESC,
             This endpoint demonstrates path-level servers.
             All operations under /inventory share the same server configuration.
           DESC
           success: { code: 200, message: 'Inventory list' },
           tags: ['operations']
      params do
        optional :warehouse_id, type: Integer, desc: 'Filter by warehouse'
      end
      get do
        [
          { sku: 'WIDGET-001', name: 'Widget', quantity: 150, warehouse_id: 1 },
          { sku: 'GADGET-002', name: 'Gadget', quantity: 75, warehouse_id: 2 }
        ]
      end

      desc 'Update inventory count',
           summary: 'Adjust inventory quantity',
           detail: 'Uses the same path-level servers as GET /inventory',
           success: { code: 200, message: 'Inventory updated' },
           tags: ['operations']
      params do
        requires :sku, type: String, desc: 'Product SKU'
        requires :adjustment, type: Integer, desc: 'Quantity adjustment (+/-)'
      end
      patch do
        { sku: params[:sku], new_quantity: 100 + params[:adjustment] }
      end
    end

    # ============================================
    # OPTIONS, HEAD HTTP Methods
    # ============================================
    resource :http_methods do
      desc 'Demonstrates OPTIONS method',
           summary: 'Get CORS headers and allowed methods',
           detail: 'Returns CORS headers and allowed HTTP methods for the resource.',
           success: { code: 200, message: 'CORS headers returned' },
           tags: ['operations']
      options 'cors' do
        header 'Access-Control-Allow-Origin', '*'
        header 'Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS'
        header 'Access-Control-Allow-Headers', 'Content-Type, Authorization'
        status 200
        nil
      end

      desc 'Demonstrates HEAD method',
           summary: 'Get resource metadata without body',
           detail: 'Returns headers only (Content-Length, Last-Modified, ETag) without response body.',
           success: { code: 200, message: 'Headers returned without body' },
           tags: ['operations']
      head 'metadata' do
        header 'Content-Length', '1234'
        header 'Last-Modified', Time.now.httpdate
        header 'ETag', '"abc123"'
        status 200
        nil
      end
    end

    # ============================================
    # Path-level Parameters
    # ============================================
    resource :items do
      route_param :item_id, type: Integer, desc: 'Item ID (path-level parameter)' do
        desc 'Get item details',
             summary: 'Retrieve an item by ID',
             detail: 'The :item_id parameter is defined at path level and shared by all operations.',
             success: { code: 200, message: 'Item details' },
             failure: [{ code: 404, message: 'Item not found' }],
             tags: ['operations']
        get do
          { id: params[:item_id], name: 'Sample Item', status: 'active' }
        end

        desc 'Update item',
             summary: 'Update an existing item',
             success: { code: 200, message: 'Item updated' },
             failure: [{ code: 404, message: 'Item not found' }],
             tags: ['operations']
        params do
          optional :name, type: String, desc: 'Item name'
          optional :status, type: String, values: %w[active inactive archived]
        end
        put do
          {
            id: params[:item_id],
            name: params[:name] || 'Updated Item',
            status: params[:status] || 'active',
            updated_at: Time.now
          }
        end

        desc 'Delete item',
             summary: 'Delete an item',
             success: { code: 204, message: 'Item deleted' },
             failure: [{ code: 404, message: 'Item not found' }],
             tags: ['operations']
        delete do
          status 204
          nil
        end
      end
    end
  end
end
