# frozen_string_literal: true

module V1
  module Entities
    # Base payment method (for polymorphic oneOf demonstration)
    class PaymentMethod < BaseEntity
      expose :id, documentation: { type: Integer }
      expose :type, documentation: {
        type: String,
        desc: 'Payment type discriminator',
        values: %w[credit_card bank_account digital_wallet]
      }
      expose :is_default, documentation: { type: 'Boolean' }
      expose :created_at, format_with: :iso_timestamp, documentation: { type: DateTime }
    end

    # Credit card payment method
    class CreditCard < PaymentMethod
      expose :card_brand, documentation: {
        type: String,
        values: %w[visa mastercard amex discover]
      }
      expose :last_four, documentation: { type: String, desc: 'Last 4 digits' }
      expose :expiry_month, documentation: { type: Integer }
      expose :expiry_year, documentation: { type: Integer }
      expose :cardholder_name, documentation: { type: String }
    end

    # Bank account payment method
    class BankAccount < PaymentMethod
      expose :bank_name, documentation: { type: String }
      expose :account_type, documentation: {
        type: String,
        values: %w[checking savings]
      }
      expose :last_four, documentation: { type: String, desc: 'Last 4 digits of account' }
      expose :routing_number_last_four, documentation: { type: String }
    end

    # Digital wallet payment method
    class DigitalWallet < PaymentMethod
      expose :provider, documentation: {
        type: String,
        values: %w[apple_pay google_pay paypal venmo]
      }
      expose :wallet_id, documentation: { type: String }
      expose :email, documentation: {
        type: String,
        format: 'email',
        nullable: true
      }
    end
  end
end
