# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    class SecuritySchemeBuilder
      OAUTH2_FLOWS = %i[authorizationCode clientCredentials implicit password].freeze
      SWAGGER_2_FLOW_MAPPING = {
        authorizationCode: 'accessCode',
        clientCredentials: 'application',
        implicit: 'implicit',
        password: 'password'
      }.freeze

      def self.build(security_config, version)
        raise ArgumentError, 'security_config cannot be nil' if security_config.nil?

        return {} if security_config.empty?

        if version.swagger_2_0?
          build_swagger_2_0(security_config)
        else
          build_openapi_3_1(security_config)
        end
      end

      private

      def self.build_openapi_3_1(config)
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
          # Unknown type - pass through
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

        # Add type-specific fields
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

      # Swagger 2.0 compatibility methods
      def self.build_swagger_2_0(config)
        case config[:type]
        when 'oauth2'
          build_swagger_2_oauth2(config)
        when 'openIdConnect', 'mutualTLS'
          # These types are not supported in Swagger 2.0
          nil
        when 'http'
          build_swagger_2_http(config)
        when 'apiKey'
          build_swagger_2_apikey(config)
        else
          config.dup
        end
      end

      def self.build_swagger_2_oauth2(config)
        return nil unless config[:flows].is_a?(Hash)

        # Get the first flow (Swagger 2.0 only supports one flow)
        flow_name, flow_config = config[:flows].first
        return nil unless flow_config

        flow_symbol = flow_name.to_sym
        return nil unless OAUTH2_FLOWS.include?(flow_symbol)

        {
          type: 'oauth2',
          description: config[:description],
          flow: SWAGGER_2_FLOW_MAPPING[flow_symbol],
          authorizationUrl: flow_config[:authorization_url],
          tokenUrl: flow_config[:token_url],
          scopes: flow_config[:scopes]
        }.compact
      end

      def self.build_swagger_2_http(config)
        # In Swagger 2.0, http schemes are converted to basic
        {
          type: 'basic',
          description: config[:description]
        }.compact
      end

      def self.build_swagger_2_apikey(config)
        {
          type: 'apiKey',
          name: config[:name],
          in: config[:in],
          description: config[:description]
        }.compact
      end
    end
  end
end
