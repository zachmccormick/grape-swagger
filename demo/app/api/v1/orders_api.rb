# frozen_string_literal: true

module V1
  class OrdersAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :orders do
      desc 'List all orders',
           is_array: true,
           success: { model: Entities::Order },
           failure: [
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['orders']
      params do
        optional :status, type: String,
                 values: %w[pending confirmed processing shipped delivered cancelled]
        optional :from_date, type: DateTime, desc: 'Filter from date'
        optional :to_date, type: DateTime, desc: 'Filter to date'
        optional :limit, type: Integer, default: 20
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
           success: { model: Entities::Order },
           failure: [
             { code: 404, message: 'Order not found' },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['orders']
      params do
        requires :id, type: Integer, desc: 'Order ID'
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
           success: { model: Entities::Order, message: 'Order created successfully' },
           failure: [
             { code: 400, message: 'Validation error' },
             { code: 422, message: 'Unprocessable Entity' }
           ],
           tags: ['orders']
      params do
        requires :items, type: Array, desc: 'Order items' do
          requires :product_id, type: Integer
          requires :quantity, type: Integer
          optional :sku, type: String, allow_blank: true
        end
        optional :shipping_address, type: String, allow_blank: true, desc: 'Shipping address (nullable)'
        optional :notes, type: String, allow_blank: true, desc: 'Order notes (nullable)'
        optional :currency, type: String, values: %w[USD EUR GBP JPY], default: 'USD'
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
            { id: i + 1, product_name: "Product #{item[:product_id]}", quantity: item[:quantity], unit_price_cents: 999 }
          end,
          shipping_address: params[:shipping_address],
          notes: params[:notes],
          created_at: Time.now,
          updated_at: Time.now
        }
        present order, with: Entities::Order
      end

      desc 'Update order status',
           success: { model: Entities::Order },
           failure: [
             { code: 400, message: 'Invalid status transition' },
             { code: 404, message: 'Order not found' }
           ],
           tags: ['orders']
      params do
        requires :id, type: Integer, desc: 'Order ID'
        requires :status, type: String,
                 values: %w[pending confirmed processing shipped delivered cancelled]
        optional :notes, type: String, allow_blank: true
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
           failure: [
             { code: 404, message: 'Order not found' },
             { code: 409, message: 'Order cannot be cancelled' }
           ],
           tags: ['orders']
      params do
        requires :id, type: Integer, desc: 'Order ID'
        optional :reason, type: String, desc: 'Cancellation reason'
      end
      delete ':id' do
        status 204
        body false
      end
    end
  end
end
