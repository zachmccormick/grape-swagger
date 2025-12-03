# frozen_string_literal: true

module V1
  # Admin API endpoints - demonstrates enhanced security requirements
  class AdminAPI < Grape::API
    format :json
    prefix :api
    version 'v1', using: :path

    resource :admin do
      # Endpoints requiring BOTH API key AND bearer token (AND relationship)
      desc 'Get system statistics',
           summary: 'Retrieve system-wide statistics',
           detail: 'Returns comprehensive system statistics. Requires both API key and bearer token.',
           security: [{ api_key: [], bearer_auth: [] }], # Both required (AND)
           success: {
             code: 200,
             examples: {
               'application/json' => {
                 total_users: 15_420,
                 active_users_24h: 3250,
                 total_orders: 89_430,
                 revenue_cents: 1_250_000_00,
                 system_health: 'healthy',
                 generated_at: '2024-01-15T12:00:00Z'
               }
             }
           },
           failure: [
             { code: 401, message: 'Unauthorized - Both API key and bearer token required' },
             { code: 403, message: 'Forbidden - Admin role required' }
           ],
           tags: ['admin']
      get 'stats' do
        {
          total_users: 15_420,
          active_users_24h: 3250,
          total_orders: 89_430,
          revenue_cents: 1_250_000_00,
          system_health: 'healthy',
          generated_at: Time.now.iso8601
        }
      end

      desc 'Get audit logs',
           summary: 'Retrieve system audit logs',
           detail: 'Returns audit trail of system events. Requires mutual TLS authentication.',
           security: [{ mutual_tls: [] }], # Requires client certificate
           is_array: true,
           success: {
             code: 200,
             examples: {
               'application/json' => [
                 {
                   id: 1,
                   event_type: 'user.login',
                   actor_id: 123,
                   actor_type: 'user',
                   ip_address: '192.168.1.1',
                   timestamp: '2024-01-15T11:30:00Z',
                   details: { method: 'oauth2', success: true }
                 }
               ]
             }
           },
           failure: [
             { code: 401, message: 'Unauthorized - Client certificate required' },
             { code: 403, message: 'Forbidden - Admin role required' }
           ],
           tags: ['admin']
      params do
        optional :event_type, type: String,
                              values: %w[user.login user.logout user.created order.created payment.processed],
                              desc: 'Filter by event type'
        optional :from, type: DateTime, desc: 'Start timestamp (ISO 8601)'
        optional :to, type: DateTime, desc: 'End timestamp (ISO 8601)'
        optional :limit, type: Integer, values: 1..1000, default: 100, desc: 'Maximum results'
      end
      get 'audit-logs' do
        [
          {
            id: 1,
            event_type: 'user.login',
            actor_id: 123,
            actor_type: 'user',
            ip_address: '192.168.1.1',
            timestamp: Time.now.iso8601,
            details: { method: 'oauth2', success: true }
          }
        ]
      end

      desc 'Get user management data',
           summary: 'Bulk user data for admin dashboard',
           detail: 'Returns user data with OAuth2 admin scope requirement.',
           security: [{ oauth2: ['admin'] }], # Requires specific OAuth scope
           is_array: true,
           success: { code: 200 },
           failure: [
             { code: 401, message: 'Unauthorized' },
             { code: 403, message: 'Forbidden - admin scope required' }
           ],
           tags: ['admin']
      params do
        optional :include_inactive, type: Boolean, default: false, desc: 'Include inactive users'
        optional :role, type: String, values: %w[admin moderator user guest], desc: 'Filter by role'
      end
      get 'users' do
        [
          { id: 1, email: 'admin@example.com', role: 'admin', is_active: true, last_login: Time.now.iso8601 },
          { id: 2, email: 'user@example.com', role: 'user', is_active: true, last_login: Time.now.iso8601 }
        ]
      end

      desc 'Trigger system maintenance',
           summary: 'Initiate maintenance mode',
           detail: 'Puts the system into maintenance mode. Accepts either OpenID Connect or mutual TLS.',
           security: [{ openid_connect: [] }, { mutual_tls: [] }], # Either one (OR)
           success: {
             code: 202,
             message: 'Maintenance initiated',
             examples: {
               'application/json' => {
                 status: 'maintenance_scheduled',
                 scheduled_at: '2024-01-15T02:00:00Z',
                 estimated_duration_minutes: 30,
                 affected_services: %w[api webhooks]
               }
             }
           },
           failure: [
             { code: 401, message: 'Unauthorized' },
             { code: 409, message: 'Maintenance already in progress' }
           ],
           tags: ['admin']
      params do
        requires :scheduled_at, type: DateTime, desc: 'When to start maintenance (ISO 8601)'
        requires :duration_minutes, type: Integer, values: 5..240, desc: 'Expected duration (5-240 minutes)'
        optional :message, type: String, desc: 'User-facing maintenance message'
        optional :affected_services, type: Array[String], desc: 'List of affected services'
      end
      post 'maintenance' do
        status 202
        {
          status: 'maintenance_scheduled',
          scheduled_at: params[:scheduled_at].iso8601,
          estimated_duration_minutes: params[:duration_minutes],
          affected_services: params[:affected_services] || ['api']
        }
      end

      desc 'Rotate API keys',
           summary: 'Generate new API credentials',
           detail: 'Rotates API keys for a service account. Requires both bearer auth and API key.',
           security: [{ api_key: [], bearer_auth: [] }],
           success: {
             code: 200,
             examples: {
               'application/json' => {
                 new_api_key: 'sk_live_new_abc123...',
                 old_key_valid_until: '2024-01-22T12:00:00Z',
                 rotated_at: '2024-01-15T12:00:00Z'
               }
             }
           },
           failure: [
             { code: 401, message: 'Unauthorized' },
             { code: 429, message: 'Rate limited - key rotation limited to once per hour' }
           ],
           tags: ['admin']
      params do
        requires :service_account_id, type: Integer, desc: 'Service account to rotate keys for'
        optional :grace_period_hours, type: Integer, values: 1..168, default: 24, desc: 'Hours old key remains valid'
      end
      post 'rotate-keys' do
        {
          new_api_key: "sk_live_new_#{SecureRandom.hex(16)}",
          old_key_valid_until: (Time.now + (params[:grace_period_hours] * 3600)).iso8601,
          rotated_at: Time.now.iso8601
        }
      end
    end
  end
end
