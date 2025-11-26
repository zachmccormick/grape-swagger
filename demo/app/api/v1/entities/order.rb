# frozen_string_literal: true

module V1
  module Entities
    # Order entity for webhook demonstrations
    class Order < BaseEntity
      expose :id, documentation: { type: Integer, desc: 'Order ID' }
      expose :order_number, documentation: { type: String, desc: 'Order reference number' }
      expose :status, documentation: {
        type: String,
        desc: 'Order status',
        values: %w[pending confirmed processing shipped delivered cancelled]
      }
      expose :total_cents, documentation: { type: Integer, desc: 'Total in cents' }
      expose :currency, documentation: {
        type: String,
        desc: 'Currency code',
        values: %w[USD EUR GBP JPY]
      }
      expose :customer, using: 'V1::Entities::UserCompact', documentation: { desc: 'Customer info' }
      expose :items, using: 'V1::Entities::OrderItem', documentation: {
        is_array: true,
        desc: 'Order items'
      }
      expose :shipping_address, documentation: {
        type: String,
        desc: 'Shipping address (nullable)',
        nullable: true
      }
      expose :notes, documentation: {
        type: String,
        desc: 'Order notes (nullable)',
        nullable: true
      }
      expose :created_at, format_with: :iso_timestamp, documentation: { type: DateTime }
      expose :updated_at, format_with: :iso_timestamp, documentation: { type: DateTime }
    end

    # Order item entity
    class OrderItem < BaseEntity
      expose :id, documentation: { type: Integer }
      expose :product_name, documentation: { type: String }
      expose :quantity, documentation: { type: Integer }
      expose :unit_price_cents, documentation: { type: Integer }
      expose :sku, documentation: { type: String, desc: 'SKU (nullable)', nullable: true }
    end
  end
end
