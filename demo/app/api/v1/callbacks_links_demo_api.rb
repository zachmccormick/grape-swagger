# frozen_string_literal: true

module V1
  # Demonstrates OpenAPI 3.1.0 callbacks and links features
  class CallbacksLinksDemoAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :callbacks do
      # ============================================
      # Callbacks (Async Webhooks)
      # ============================================
      desc 'Demonstrates callbacks (webhooks triggered by this operation)',
           summary: 'Start async processing with callback',
           detail: <<~DESC,
             This operation starts an async job and will call back to your URL
             when processing is complete.

             The callback URL will receive a POST request with the job result.
           DESC
           callbacks: {
             jobComplete: {
               url: '{$request.body#/callback_url}',
               method: :post,
               summary: 'Job completion callback',
               description: 'Called when the async job finishes processing',
               request: {
                 schema: {
                   type: 'object',
                   properties: {
                     job_id: { type: 'string', description: 'The job identifier' },
                     status: { type: 'string', enum: %w[completed failed], description: 'Job completion status' },
                     result: { type: 'object', description: 'Job result data' },
                     completed_at: { type: 'string', format: 'date-time' }
                   },
                   required: %w[job_id status completed_at]
                 }
               },
               responses: {
                 200 => { description: 'Callback received successfully' },
                 400 => { description: 'Invalid callback payload' }
               }
             },
             jobProgress: {
               url: '{$request.body#/callback_url}',
               method: :post,
               summary: 'Job progress callback',
               description: 'Called periodically with job progress updates',
               request: {
                 schema: {
                   type: 'object',
                   properties: {
                     job_id: { type: 'string' },
                     progress_percent: { type: 'integer', minimum: 0, maximum: 100 },
                     current_step: { type: 'string' }
                   }
                 }
               },
               responses: {
                 200 => { description: 'Progress update acknowledged' }
               }
             }
           },
           success: { code: 202, message: 'Job accepted for processing' },
           failure: [{ code: 400, message: 'Invalid job parameters' }],
           tags: ['callbacks']
      params do
        requires :job_type, type: String, values: %w[export import analyze], desc: 'Type of async job'
        requires :callback_url, type: String, desc: 'URL to receive completion callback'
        optional :notify_progress, type: Boolean, default: false, desc: 'Whether to send progress callbacks'
      end
      post 'async-jobs' do
        job_id = "job_#{SecureRandom.hex(8)}"
        {
          job_id: job_id,
          status: 'pending',
          estimated_completion: Time.now + 300,
          callback_url: params[:callback_url]
        }
      end

      # ============================================
      # Reusable Callbacks via $ref
      # ============================================
      desc 'Demonstrates reusable callbacks via component reference',
           summary: 'Subscribe to events with reusable callback',
           detail: <<~DESC,
             This endpoint demonstrates referencing reusable callbacks defined
             in `#/components/callbacks`:

             ```yaml
             callbacks:
               onEvent:
                 $ref: '#/components/callbacks/EventNotification'
             ```
           DESC
           consumes: ['application/json'],
           success: { code: 201, message: 'Subscription created' },
           failure: [
             { code: 400, message: 'Invalid callback URL' },
             { code: 409, message: 'Subscription already exists' }
           ],
           callbacks: {
             onEvent: { '$ref' => API.callback_ref(:EventNotification) }
           },
           tags: ['callbacks']
      params do
        requires :callback_url, type: String, documentation: {
          desc: 'URL to receive event notifications (must be HTTPS)',
          format: 'uri'
        }
        requires :event_types, type: Array[String], documentation: {
          desc: 'Event types to subscribe to',
          example: %w[created updated deleted]
        }
        optional :secret, type: String, documentation: {
          desc: 'Shared secret for HMAC signature verification'
        }
      end
      post 'subscriptions' do
        {
          subscription_id: "sub_#{SecureRandom.hex(8)}",
          callback_url: params[:callback_url],
          event_types: params[:event_types],
          status: 'active',
          created_at: Time.now
        }
      end

      # ============================================
      # Callback Runtime Expressions Demo
      # ============================================
      desc 'Demonstrates inline callback with runtime expressions',
           summary: 'Register webhook with all expression types',
           detail: <<~DESC,
             This endpoint demonstrates ALL callback runtime expression types:

             - `{$url}` - The full URL of the callback
             - `{$method}` - The HTTP method used
             - `{$request.query.param}` - Query parameter value
             - `{$request.header.name}` - Request header value
             - `{$request.body#/pointer}` - JSON pointer into request body
           DESC
           consumes: ['application/json'],
           success: { code: 201, message: 'Webhook registered' },
           callbacks: {
             onBodyEvent: {
               '{$request.body#/webhook_url}' => {
                 post: {
                   summary: 'Body-based callback',
                   requestBody: {
                     content: {
                       'application/json' => {
                         schema: { type: 'object', properties: { event: { type: 'string' } } }
                       }
                     }
                   },
                   responses: { '200' => { description: 'OK' } }
                 }
               }
             },
             onQueryEvent: {
               '{$request.query.callback}' => {
                 post: {
                   summary: 'Query-based callback',
                   requestBody: {
                     content: {
                       'application/json' => {
                         schema: { type: 'object', properties: { data: { type: 'string' } } }
                       }
                     }
                   },
                   responses: { '200' => { description: 'OK' } }
                 }
               }
             },
             onHeaderEvent: {
               '{$request.header.X-Webhook-URL}' => {
                 post: {
                   summary: 'Header-based callback',
                   requestBody: {
                     content: {
                       'application/json' => {
                         schema: { type: 'object', properties: { result: { type: 'string' } } }
                       }
                     }
                   },
                   responses: { '200' => { description: 'OK' } }
                 }
               }
             }
           },
           tags: ['callbacks']
      params do
        requires :webhook_url, type: String, desc: 'Webhook URL (used via {$request.body#/webhook_url})'
        optional :callback, type: String, documentation: { in: 'query' }, desc: 'Callback URL (query param)'
      end
      post 'webhooks' do
        {
          id: "hook_#{SecureRandom.hex(8)}",
          webhook_url: params[:webhook_url],
          query_callback: params[:callback],
          created_at: Time.now
        }
      end
    end

    resource :links do
      # ============================================
      # Links (Response Links to Other Operations)
      # ============================================
      desc 'Create a resource with links to related operations',
           summary: 'Create a task with hypermedia links',
           detail: <<~DESC,
             This operation demonstrates OpenAPI 3.1.0 Links - references to other
             operations that can be invoked using values from this response.

             The response includes links to:
             - Get the created task by ID
             - Update the task status
             - Delete the task
           DESC
           links: {
             200 => {
               GetTaskById: {
                 operation_id: 'getLinksTask',
                 parameters: { id: '$response.body#/id' },
                 description: 'Get the created task by its ID'
               },
               UpdateTaskStatus: {
                 operation_id: 'updateLinksTaskStatus',
                 parameters: { id: '$response.body#/id' },
                 request_body: { status: 'in_progress' },
                 description: 'Update the task status'
               }
             }
           },
           success: { code: 200, message: 'Task created with links' },
           tags: ['links']
      params do
        requires :title, type: String, desc: 'Task title'
        optional :description, type: String, desc: 'Task description'
        optional :priority, type: String, values: %w[low medium high], default: 'medium'
      end
      post 'tasks' do
        {
          id: rand(1000..9999),
          title: params[:title],
          description: params[:description],
          priority: params[:priority],
          status: 'pending',
          created_at: Time.now
        }
      end

      desc 'Get task by ID (linked from create)',
           summary: 'Retrieve a task',
           operation_id: 'getLinksTask',
           success: { code: 200, message: 'Task details' },
           failure: [{ code: 404, message: 'Task not found' }],
           tags: ['links']
      params do
        requires :id, type: Integer, desc: 'Task ID'
      end
      get 'tasks/:id' do
        {
          id: params[:id],
          title: 'Sample Task',
          status: 'pending',
          created_at: Time.now - 3600
        }
      end

      desc 'Update task status (linked from create)',
           summary: 'Update task status',
           operation_id: 'updateLinksTaskStatus',
           success: { code: 200, message: 'Task updated' },
           failure: [{ code: 404, message: 'Task not found' }],
           tags: ['links']
      params do
        requires :id, type: Integer, desc: 'Task ID'
        requires :status, type: String, values: %w[pending in_progress completed cancelled]
      end
      patch 'tasks/:id/status' do
        {
          id: params[:id],
          status: params[:status],
          updated_at: Time.now
        }
      end

      # ============================================
      # Links with operationRef and server
      # ============================================
      desc 'Create order with full Link Object features',
           summary: 'Create order with external links',
           detail: <<~DESC,
             This operation demonstrates ALL Link Object fields:

             - `operationRef`: Reference to operation in another document
             - `operationId`: Reference to operation in this document
             - `parameters`: Map of parameters to runtime expressions
             - `requestBody`: Request body for the linked operation
             - `description`: Human-readable description
             - `server`: Override the server URL for the linked operation
           DESC
           links: {
             201 => {
               GetOrderDetails: {
                 operation_id: 'getLinksOrder',
                 parameters: { order_id: '$response.body#/id' },
                 description: 'Retrieve the order details'
               },
               TrackShipment: {
                 operation_ref: 'https://shipping.example.com/api#/paths/~1track~1{trackingNumber}/get',
                 parameters: { trackingNumber: '$response.body#/tracking_number' },
                 description: 'Track the shipment (external service)',
                 server: {
                   url: 'https://shipping.example.com',
                   description: 'External shipping API'
                 }
               },
               CancelOrder: {
                 operation_id: 'cancelLinksOrder',
                 parameters: { order_id: '$response.body#/id' },
                 request_body: { reason: 'Customer requested cancellation' },
                 description: 'Cancel the order'
               }
             }
           },
           success: { code: 201, message: 'Order created with links' },
           failure: [{ code: 400, message: 'Invalid order data' }],
           tags: ['links']
      params do
        requires :product_id, type: Integer, desc: 'Product ID to order'
        requires :quantity, type: Integer, desc: 'Order quantity'
        optional :shipping_address, type: Hash, desc: 'Shipping address' do
          requires :street, type: String
          requires :city, type: String
          requires :postal_code, type: String
        end
      end
      post 'orders' do
        status 201
        {
          id: rand(10_000..99_999),
          product_id: params[:product_id],
          quantity: params[:quantity],
          tracking_number: "TRK#{SecureRandom.hex(6).upcase}",
          status: 'confirmed',
          created_at: Time.now
        }
      end

      desc 'Get order by ID (linked from create)',
           summary: 'Get order details',
           operation_id: 'getLinksOrder',
           success: { code: 200, message: 'Order details' },
           failure: [{ code: 404, message: 'Order not found' }],
           tags: ['links']
      params do
        requires :order_id, type: Integer, desc: 'Order ID'
      end
      get 'orders/:order_id' do
        {
          id: params[:order_id],
          product_id: 123,
          quantity: 2,
          status: 'confirmed',
          created_at: Time.now - 3600
        }
      end

      desc 'Cancel order (linked from create)',
           summary: 'Cancel an order',
           operation_id: 'cancelLinksOrder',
           success: { code: 200, message: 'Order cancelled' },
           failure: [
             { code: 404, message: 'Order not found' },
             { code: 409, message: 'Order cannot be cancelled' }
           ],
           tags: ['links']
      params do
        requires :order_id, type: Integer, desc: 'Order ID'
        requires :reason, type: String, desc: 'Cancellation reason'
      end
      post 'orders/:order_id/cancel' do
        {
          id: params[:order_id],
          status: 'cancelled',
          reason: params[:reason],
          cancelled_at: Time.now
        }
      end
    end
  end
end
