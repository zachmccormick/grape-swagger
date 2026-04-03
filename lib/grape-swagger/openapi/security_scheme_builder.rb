# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Builds OpenAPI 3.1.0 security scheme objects from configuration.
    # Swagger 2.0 security definitions are passed through as-is by grape-swagger's
    # existing endpoint logic - this builder only handles OpenAPI 3.1.0.
    class SecuritySchemeBuilder
      OAUTH2_FLOWS = %i[authorizationCode clientCredentials implicit password].freeze

      def self.build(config)
        return {} if config.nil? || config.empty?

        case config[:type]
        when 'oauth2'
          build_oauth2(config)
        when 'openIdConnect'
          build_openid_connect(config)
        when 'mutualTLS'
          build_mutual_tls(config)
        when 'http', 'apiKey'
          build_basic_scheme(config)
        else
          config.dup
        end
      end

      def self.build_oauth2(config)
        {
          type: 'oauth2',
          description: config[:description],
          flows: build_oauth2_flows(config[:flows])
        }.compact
      end

      def self.build_oauth2_flows(flows)
        return {} unless flows.is_a?(Hash)

        flows.each_with_object({}) do |(flow_name, flow_config), result|
          flow_symbol = flow_name.to_sym
          next unless OAUTH2_FLOWS.include?(flow_symbol)

          result[flow_symbol] = {
            authorizationUrl: flow_config[:authorization_url],
            tokenUrl: flow_config[:token_url],
            refreshUrl: flow_config[:refresh_url],
            scopes: flow_config[:scopes]
          }.compact
        end
      end

      def self.build_openid_connect(config)
        {
          type: 'openIdConnect',
          description: config[:description],
          openIdConnectUrl: config[:openid_connect_url]
        }.compact
      end

      def self.build_mutual_tls(config)
        {
          type: 'mutualTLS',
          description: config[:description]
        }.compact
      end

      def self.build_basic_scheme(config)
        result = {
          type: config[:type],
          description: config[:description]
        }

        case config[:type]
        when 'http'
          result[:scheme] = config[:scheme]
          result[:bearerFormat] = config[:bearerFormat]
        when 'apiKey'
          result[:name] = config[:name]
          result[:in] = config[:in]
        end

        result.compact
      end
    end
  end
end
