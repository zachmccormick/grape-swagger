# frozen_string_literal: true

module V1
  class OrdersAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :orders do
      desc 'List all orders',
           summary: 'Get a paginated list of orders',
           detail: 'Returns all orders with optional filtering by status and date range.',
           is_array: true,
           success: {
             model: Entities::Order,
             examples: {
               'application/json' => [
                 {
                   id: 1, order_number: 'ORD-001', status: 'confirmed',
                   total_cents: 4999, currency: 'USD',
                   customer: { id: 1, name: 'John Doe', email: 'john@example.com' }
                 }
               ]
             }
           },
           failure: [
             { code: 401, message: 'Unauthorized', examples: { 'application/json' => { error: 'Invalid token' } } }
           ],
           tags: ['orders']
      params do
        optional :status, type: String,
                          values: %w[pending confirmed processing shipped delivered cancelled],
                          desc: 'Filter by order status'
        optional :from_date, type: DateTime, desc: 'Filter orders from this date (ISO 8601)'
        optional :to_date, type: DateTime, desc: 'Filter orders until this date (ISO 8601)'
        optional :limit, type: Integer, values: 1..100, default: 20, desc: 'Maximum number of results'
        optional :offset, type: Integer, values: 0..10_000, default: 0, desc: 'Pagination offset'
      end
      get do
        orders = [
          {
            id: 1, order_number: 'ORD-001', status: 'confirmed',
            total_cents: 4999, currency: 'USD',
            customer: { id: 1, name: 'John Doe', email: 'john@example.com' },
            items: [{ id: 1, product_name: 'Widget', quantity: 2, unit_price_cents: 2499 }],
            created_at: Time.now
          }
        ]
        present orders, with: Entities::Order
      end

      desc 'Get order by ID',
           summary: 'Retrieve a specific order',
           detail: 'Returns detailed information about an order including items and customer.',
           success: {
             model: Entities::Order,
             examples: {
               'application/json' => {
                 id: 1, order_number: 'ORD-0001', status: 'confirmed',
                 total_cents: 4999, currency: 'USD',
                 customer: { id: 1, name: 'John Doe', email: 'john@example.com' },
                 items: [{ id: 1, product_name: 'Widget', quantity: 2, unit_price_cents: 2499 }]
               }
             }
           },
           failure: [
             { code: 404, message: 'Order not found',
               examples: { 'application/json' => { error: 'Order with ID 999 not found' } } },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['orders']
      params do
        requires :id, type: Integer, values: 1..2_147_483_647, desc: 'Unique order identifier'
      end
      get ':id' do
        order = {
          id: params[:id], order_number: "ORD-#{params[:id].to_s.rjust(4, '0')}",
          status: 'confirmed', total_cents: 4999, currency: 'USD',
          customer: { id: 1, name: 'John Doe', email: 'john@example.com' },
          items: [{ id: 1, product_name: 'Widget', quantity: 2, unit_price_cents: 2499 }],
          shipping_address: '123 Main St, City, ST 12345',
          created_at: Time.now, updated_at: Time.now
        }
        present order, with: Entities::Order
      end

      desc 'Create a new order',
           summary: 'Place a new order',
           detail: 'Creates a new order with the provided items and shipping information.',
           success: {
             model: Entities::Order,
             message: 'Order created successfully',
             examples: {
               'application/json' => {
                 id: 1234, order_number: 'ORD-1234', status: 'pending',
                 total_cents: 2998, currency: 'USD',
                 items: [{ id: 1, product_name: 'Product 1', quantity: 2, unit_price_cents: 1499 }]
               }
             }
           },
           failure: [
             { code: 400, message: 'Validation error',
               examples: { 'application/json' => { error: 'Items cannot be empty' } } },
             { code: 422, message: 'Unprocessable Entity' }
           ],
           tags: ['orders']
      params do
        requires :items, type: Array, desc: 'Array of order items' do
          requires :product_id, type: Integer, values: 1..2_147_483_647, desc: 'Product identifier'
          requires :quantity, type: Integer, values: 1..1000, desc: 'Quantity to order'
          optional :sku, type: String, allow_blank: true, desc: 'Product SKU'
        end
        optional :shipping_address, type: String, allow_blank: true, desc: 'Shipping address'
        optional :notes, type: String, allow_blank: true, desc: 'Order notes'
        optional :currency, type: String, values: %w[USD EUR GBP JPY], default: 'USD', desc: 'Currency code'
      end
      post do
        order = {
          id: rand(1000..9999),
          order_number: "ORD-#{rand(1000..9999)}",
          status: 'pending',
          total_cents: 4999,
          currency: params[:currency],
          customer: { id: 1, name: 'Demo Customer', email: 'demo@example.com' },
          items: params[:items].map.with_index do |item, i|
            { id: i + 1, product_name: "Product #{item[:product_id]}", quantity: item[:quantity],
              unit_price_cents: 999 }
          end,
          shipping_address: params[:shipping_address],
          notes: params[:notes],
          created_at: Time.now,
          updated_at: Time.now
        }
        present order, with: Entities::Order
      end

      desc 'Update order status',
           summary: 'Change order status',
           detail: 'Transitions the order to a new status (must be a valid transition).',
           success: {
             model: Entities::Order,
             examples: {
               'application/json' => { id: 1, order_number: 'ORD-0001', status: 'shipped',
                                       updated_at: '2024-01-15T12:00:00Z' }
             }
           },
           failure: [
             { code: 400, message: 'Invalid status transition',
               examples: { 'application/json' => { error: 'Cannot transition from pending to delivered' } } },
             { code: 404, message: 'Order not found' }
           ],
           tags: ['orders']
      params do
        requires :id, type: Integer, values: 1..2_147_483_647, desc: 'Unique order identifier'
        requires :status, type: String,
                          values: %w[pending confirmed processing shipped delivered cancelled],
                          desc: 'New order status'
        optional :notes, type: String, allow_blank: true, desc: 'Status change notes'
      end
      patch ':id/status' do
        order = {
          id: params[:id], order_number: "ORD-#{params[:id]}",
          status: params[:status], total_cents: 4999, currency: 'USD',
          customer: { id: 1, name: 'Demo', email: 'demo@example.com' },
          items: [], updated_at: Time.now
        }
        present order, with: Entities::Order
      end

      desc 'Cancel an order',
           summary: 'Cancel an existing order',
           detail: 'Cancels an order if it has not been shipped yet.',
           failure: [
             { code: 404, message: 'Order not found' },
             { code: 409, message: 'Order cannot be cancelled',
               examples: { 'application/json' => { error: 'Order has already been shipped' } } }
           ],
           tags: ['orders']
      params do
        requires :id, type: Integer, values: 1..2_147_483_647, desc: 'Unique order identifier'
        optional :reason, type: String, desc: 'Reason for cancellation'
      end
      delete ':id' do
        status 204
        body false
      end
    end
  end
end
