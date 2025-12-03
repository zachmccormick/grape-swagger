# frozen_string_literal: true

module V1
  # Demonstrates OpenAPI 3.1.0 JSON Schema features
  class SchemaDemoAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :schemas do
      # ============================================
      # readOnly and writeOnly Properties
      # ============================================
      desc 'Demonstrates readOnly/writeOnly schema properties',
           summary: 'Get user with read-only computed fields',
           detail: <<~DESC,
             This endpoint returns a user object where some fields are:
             - `readOnly`: Computed by the server, not accepted in requests (id, created_at)
             - `writeOnly`: Accepted in requests but never returned (password)
           DESC
           success: { code: 200, message: 'User details with computed fields', model: V1::Entities::User },
           tags: ['schemas']
      params do
        requires :id, type: Integer, desc: 'User ID'
      end
      get 'users/:id' do
        {
          id: params[:id],
          username: 'johndoe',
          email: 'john@example.com',
          created_at: Time.now - 86_400,
          updated_at: Time.now
        }
      end

      desc 'Create user with writeOnly password field',
           summary: 'Create a new user',
           detail: 'Password is writeOnly - accepted on create but never returned in responses.',
           success: { code: 201, message: 'User created', model: V1::Entities::User },
           failure: [{ code: 400, message: 'Validation error' }],
           tags: ['schemas']
      params do
        requires :username, type: String, desc: 'Username'
        requires :email, type: String, desc: 'Email address'
        requires :password, type: String, documentation: { write_only: true },
                            desc: 'Password (write-only, never returned)'
        optional :password_confirmation, type: String, documentation: { write_only: true },
                                         desc: 'Password confirmation'
      end
      post 'users' do
        {
          id: rand(1000..9999),
          username: params[:username],
          email: params[:email],
          created_at: Time.now
        }
      end

      # ============================================
      # Schema Validation Keywords Demo
      # ============================================
      desc 'Demonstrates schema validation keywords',
           summary: 'Create validated resource',
           detail: <<~DESC,
             This endpoint demonstrates various JSON Schema validation keywords:

             **String validation**: minLength, maxLength, pattern
             **Numeric validation**: minimum, maximum, exclusiveMinimum, exclusiveMaximum, multipleOf
             **Array validation**: minItems, maxItems, uniqueItems
             **Object validation**: minProperties, maxProperties, additionalProperties
           DESC
           consumes: ['application/json'],
           success: { code: 201, message: 'Resource created' },
           failure: [{ code: 422, message: 'Validation failed' }],
           tags: ['schemas']
      params do
        requires :username, type: String, documentation: {
          desc: 'Username (3-20 chars, alphanumeric)',
          minLength: 3,
          maxLength: 20,
          pattern: '^[a-zA-Z0-9_]+$'
        }
        requires :email, type: String, documentation: {
          desc: 'Email address',
          format: 'email',
          maxLength: 255
        }
        requires :age, type: Integer, documentation: {
          desc: 'Age (must be 18-120)',
          minimum: 18,
          maximum: 120
        }
        requires :score, type: Float, documentation: {
          desc: 'Score (0 < score < 100, must be multiple of 0.5)',
          exclusiveMinimum: 0,
          exclusiveMaximum: 100,
          multipleOf: 0.5
        }
        requires :tags, type: Array[String], documentation: {
          desc: 'Tags (1-10 unique items)',
          minItems: 1,
          maxItems: 10,
          uniqueItems: true
        }
        optional :metadata, type: Hash, documentation: {
          desc: 'Custom metadata (1-5 properties)',
          minProperties: 1,
          maxProperties: 5,
          additionalProperties: { type: 'string' }
        }
      end
      post 'validated' do
        {
          id: rand(1000..9999),
          username: params[:username],
          email: params[:email],
          age: params[:age],
          score: params[:score],
          tags: params[:tags],
          metadata: params[:metadata] || {},
          created_at: Time.now
        }
      end

      # ============================================
      # Discriminator with Mapping Demo
      # ============================================
      desc 'Demonstrates discriminator with explicit mapping',
           summary: 'Create notification with type-based polymorphism',
           detail: <<~DESC,
             This endpoint demonstrates the Discriminator Object with explicit mapping:

             ```yaml
             discriminator:
               propertyName: notification_type
               mapping:
                 email: '#/components/schemas/EmailNotification'
                 sms: '#/components/schemas/SmsNotification'
             ```
           DESC
           consumes: ['application/json'],
           success: { code: 201, message: 'Notification queued' },
           failure: [{ code: 400, message: 'Invalid notification type' }],
           tags: ['schemas']
      params do
        requires :notification, type: Hash, documentation: {
          param_type: 'body',
          desc: 'Notification payload - type determines required fields',
          schema: {
            oneOf: [
              {
                type: 'object',
                title: 'EmailNotification',
                properties: {
                  notification_type: { type: 'string', enum: ['email'] },
                  to_email: { type: 'string', format: 'email' },
                  subject: { type: 'string' },
                  body_html: { type: 'string' }
                },
                required: %w[notification_type to_email subject body_html]
              },
              {
                type: 'object',
                title: 'SmsNotification',
                properties: {
                  notification_type: { type: 'string', enum: ['sms'] },
                  phone_number: { type: 'string' },
                  message: { type: 'string', maxLength: 160 }
                },
                required: %w[notification_type phone_number message]
              },
              {
                type: 'object',
                title: 'PushNotification',
                properties: {
                  notification_type: { type: 'string', enum: ['push'] },
                  device_token: { type: 'string' },
                  title: { type: 'string' },
                  body: { type: 'string' },
                  badge_count: { type: 'integer' }
                },
                required: %w[notification_type device_token title body]
              }
            ],
            discriminator: {
              propertyName: 'notification_type',
              mapping: {
                'email' => '#/components/schemas/EmailNotification',
                'sms' => '#/components/schemas/SmsNotification',
                'push' => '#/components/schemas/PushNotification'
              }
            }
          }
        } do
          requires :notification_type, type: String, values: %w[email sms push]
        end
      end
      post 'notifications' do
        notification_id = "notif_#{SecureRandom.hex(8)}"
        {
          id: notification_id,
          type: params[:notification][:notification_type],
          status: 'queued',
          queued_at: Time.now
        }
      end

      # ============================================
      # Schema title, const, anyOf, not Demo
      # ============================================
      desc 'Demonstrates schema composition keywords',
           summary: 'Create typed event',
           detail: <<~DESC,
             This endpoint demonstrates advanced schema keywords:

             - **title**: Human-readable schema name
             - **const**: Fixed constant value
             - **anyOf**: Value matches any of the listed schemas
             - **not**: Value must NOT match the schema
           DESC
           consumes: ['application/json'],
           success: { code: 201, message: 'Event created' },
           tags: ['schemas']
      params do
        requires :event, type: Hash, documentation: {
          param_type: 'body',
          desc: 'Event payload',
          schema: {
            title: 'EventPayload',
            type: 'object',
            properties: {
              api_version: {
                type: 'string',
                const: 'v2',
                description: 'API version (must be exactly "v2")'
              },
              identifier: {
                anyOf: [
                  { type: 'string', format: 'uuid', title: 'UUID Identifier' },
                  { type: 'integer', minimum: 1, title: 'Numeric Identifier' },
                  { type: 'string', pattern: '^[A-Z]{3}-[0-9]{6}$', title: 'Code Identifier' }
                ],
                description: 'Event identifier (UUID, integer, or code format)'
              },
              status: {
                type: 'string',
                not: { enum: %w[deleted archived] },
                description: 'Status (cannot be "deleted" or "archived")'
              },
              source: {
                title: 'EventSource',
                type: 'object',
                properties: {
                  system: { type: 'string' },
                  component: { type: 'string' }
                }
              }
            },
            required: %w[api_version identifier status]
          }
        } do
          requires :api_version, type: String
          requires :identifier, type: String
          requires :status, type: String
        end
      end
      post 'typed-events' do
        {
          event_id: SecureRandom.uuid,
          api_version: params[:event][:api_version],
          identifier: params[:event][:identifier],
          status: params[:event][:status],
          received_at: Time.now
        }
      end

      # ============================================
      # Schema Conditional (if/then/else) Demo
      # ============================================
      desc 'Demonstrates conditional schema validation',
           summary: 'Create conditional resource',
           detail: <<~DESC,
             This endpoint demonstrates JSON Schema conditional keywords:

             ```json
             {
               "if": { "properties": { "type": { "const": "premium" } } },
               "then": { "required": ["premium_features"] },
               "else": { "required": ["basic_tier"] }
             }
             ```
           DESC
           consumes: ['application/json'],
           success: { code: 201, message: 'Resource created' },
           tags: ['schemas']
      params do
        requires :resource, type: Hash, documentation: {
          param_type: 'body',
          desc: 'Resource with conditional requirements',
          schema: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              type: { type: 'string', enum: %w[basic premium enterprise] },
              basic_tier: { type: 'string', description: 'Required for basic type' },
              premium_features: {
                type: 'array',
                items: { type: 'string' },
                description: 'Required for premium type'
              },
              enterprise_config: {
                type: 'object',
                description: 'Required for enterprise type'
              }
            },
            required: %w[name type],
            if: { properties: { type: { const: 'premium' } } },
            then: { required: ['premium_features'] },
            else: {
              if: { properties: { type: { const: 'enterprise' } } },
              then: { required: ['enterprise_config'] },
              else: { required: ['basic_tier'] }
            }
          }
        } do
          requires :name, type: String
          requires :type, type: String, values: %w[basic premium enterprise]
        end
      end
      post 'conditional' do
        {
          id: rand(1000..9999),
          name: params[:resource][:name],
          type: params[:resource][:type],
          created_at: Time.now
        }
      end

      # ============================================
      # Format Demonstrations
      # ============================================
      desc 'Demonstrates various format types',
           summary: 'Create record with typed fields',
           detail: <<~DESC,
             This endpoint demonstrates various OpenAPI format types:

             **Integer formats**: int32, int64
             **Number formats**: float, double
             **String formats**: date, date-time, password, byte, binary
             **Special formats**: uuid, email, uri, hostname, ipv4, ipv6
           DESC
           consumes: ['application/json'],
           success: { code: 201, message: 'Record created' },
           tags: ['schemas']
      params do
        requires :count, type: Integer, documentation: { desc: '32-bit integer', format: 'int32' }
        requires :big_id, type: Integer, documentation: { desc: '64-bit integer', format: 'int64' }
        requires :temperature, type: Float, documentation: { desc: 'Float value', format: 'float' }
        requires :precise_value, type: Float, documentation: { desc: 'Double precision', format: 'double' }
        requires :birth_date, type: Date, documentation: { desc: 'Date only (YYYY-MM-DD)', format: 'date' }
        requires :created_at, type: DateTime, documentation: { desc: 'Full date-time', format: 'date-time' }
        requires :secret, type: String, documentation: { desc: 'Password (masked in UI)', format: 'password' }
        optional :encoded_data, type: String, documentation: { desc: 'Base64 encoded', format: 'byte' }
        requires :record_id, type: String, documentation: { desc: 'UUID identifier', format: 'uuid' }
        requires :contact_email, type: String, documentation: { desc: 'Email address', format: 'email' }
        optional :website, type: String, documentation: { desc: 'Website URL', format: 'uri' }
        optional :server_host, type: String, documentation: { desc: 'Hostname', format: 'hostname' }
        optional :ipv4_address, type: String, documentation: { desc: 'IPv4 address', format: 'ipv4' }
        optional :ipv6_address, type: String, documentation: { desc: 'IPv6 address', format: 'ipv6' }
      end
      post 'formatted' do
        {
          id: params[:record_id],
          count: params[:count],
          big_id: params[:big_id],
          temperature: params[:temperature],
          precise_value: params[:precise_value],
          birth_date: params[:birth_date],
          created_at: params[:created_at],
          contact_email: params[:contact_email],
          website: params[:website],
          server_host: params[:server_host],
          ipv4_address: params[:ipv4_address],
          ipv6_address: params[:ipv6_address],
          stored_at: Time.now
        }
      end
    end
  end
end
