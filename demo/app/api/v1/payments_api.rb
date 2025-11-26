# frozen_string_literal: true

module V1
  class PaymentsAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :payment_methods do
      desc 'List payment methods',
           is_array: true,
           success: { model: Entities::PaymentMethod },
           failure: [{ code: 401, message: 'Unauthorized' }],
           notes: 'Returns polymorphic payment methods (credit_card, bank_account, digital_wallet)',
           tags: ['payments']
      get do
        methods = [
          {
            id: 1, type: 'credit_card', is_default: true,
            card_brand: 'visa', last_four: '4242',
            expiry_month: 12, expiry_year: 2025, cardholder_name: 'John Doe',
            created_at: Time.now
          },
          {
            id: 2, type: 'bank_account', is_default: false,
            bank_name: 'Chase', account_type: 'checking',
            last_four: '6789', routing_number_last_four: '1234',
            created_at: Time.now
          },
          {
            id: 3, type: 'digital_wallet', is_default: false,
            provider: 'apple_pay', wallet_id: 'wallet_abc123', email: nil,
            created_at: Time.now
          }
        ]
        present methods, with: Entities::PaymentMethod
      end

      desc 'Get payment method by ID',
           success: { model: Entities::PaymentMethod },
           failure: [
             { code: 404, message: 'Payment method not found' },
             { code: 401, message: 'Unauthorized' }
           ],
           tags: ['payments']
      params do
        requires :id, type: Integer, desc: 'Payment method ID'
      end
      get ':id' do
        method = {
          id: params[:id], type: 'credit_card', is_default: true,
          card_brand: 'visa', last_four: '4242',
          expiry_month: 12, expiry_year: 2025, cardholder_name: 'John Doe',
          created_at: Time.now
        }
        present method, with: Entities::CreditCard
      end

      desc 'Add a credit card',
           success: { model: Entities::CreditCard },
           failure: [
             { code: 400, message: 'Invalid card details' },
             { code: 422, message: 'Card declined' }
           ],
           tags: ['payments']
      params do
        requires :card_number, type: String, desc: 'Card number (will be tokenized)'
        requires :expiry_month, type: Integer, values: (1..12).to_a
        requires :expiry_year, type: Integer
        requires :cvv, type: String, desc: 'Security code'
        requires :cardholder_name, type: String
        optional :is_default, type: Boolean, default: false
      end
      post 'credit_cards' do
        card = {
          id: rand(1000..9999), type: 'credit_card',
          is_default: params[:is_default],
          card_brand: 'visa', last_four: params[:card_number][-4..],
          expiry_month: params[:expiry_month], expiry_year: params[:expiry_year],
          cardholder_name: params[:cardholder_name],
          created_at: Time.now
        }
        present card, with: Entities::CreditCard
      end

      desc 'Add a bank account',
           success: { model: Entities::BankAccount },
           failure: [
             { code: 400, message: 'Invalid bank details' },
             { code: 422, message: 'Account verification failed' }
           ],
           tags: ['payments']
      params do
        requires :bank_name, type: String
        requires :account_type, type: String, values: %w[checking savings]
        requires :account_number, type: String, desc: 'Account number (will be tokenized)'
        requires :routing_number, type: String
        optional :is_default, type: Boolean, default: false
      end
      post 'bank_accounts' do
        account = {
          id: rand(1000..9999), type: 'bank_account',
          is_default: params[:is_default],
          bank_name: params[:bank_name], account_type: params[:account_type],
          last_four: params[:account_number][-4..],
          routing_number_last_four: params[:routing_number][-4..],
          created_at: Time.now
        }
        present account, with: Entities::BankAccount
      end

      desc 'Add a digital wallet',
           success: { model: Entities::DigitalWallet },
           failure: [
             { code: 400, message: 'Invalid wallet token' },
             { code: 422, message: 'Wallet linking failed' }
           ],
           tags: ['payments']
      params do
        requires :provider, type: String, values: %w[apple_pay google_pay paypal venmo]
        requires :wallet_token, type: String, desc: 'Wallet provider token'
        optional :email, type: String, desc: 'Associated email (nullable)', allow_blank: true
        optional :is_default, type: Boolean, default: false
      end
      post 'digital_wallets' do
        wallet = {
          id: rand(1000..9999), type: 'digital_wallet',
          is_default: params[:is_default],
          provider: params[:provider],
          wallet_id: "wallet_#{SecureRandom.hex(8)}",
          email: params[:email],
          created_at: Time.now
        }
        present wallet, with: Entities::DigitalWallet
      end

      desc 'Set default payment method',
           success: { model: Entities::PaymentMethod },
           failure: [
             { code: 404, message: 'Payment method not found' }
           ],
           tags: ['payments']
      params do
        requires :id, type: Integer, desc: 'Payment method ID'
      end
      patch ':id/default' do
        method = { id: params[:id], type: 'credit_card', is_default: true, created_at: Time.now }
        present method, with: Entities::PaymentMethod
      end

      desc 'Remove a payment method',
           failure: [
             { code: 404, message: 'Payment method not found' },
             { code: 409, message: 'Cannot remove default payment method' }
           ],
           tags: ['payments']
      params do
        requires :id, type: Integer, desc: 'Payment method ID'
      end
      delete ':id' do
        status 204
        body false
      end
    end
  end
end
