# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    module PathParamsExtension
      # DSL method to mark parameters as path-level for OpenAPI documentation.
      #
      # Parameters marked via path_params will be moved to the path level
      # in the OpenAPI output, avoiding duplication across operations.
      #
      # @example Using with route_param
      #   namespace :users do
      #     route_param :user_id, type: Integer, desc: 'User ID' do
      #       path_params :user_id  # Mark as path-level
      #
      #       get { ... }  # user_id appears at path level, not here
      #       put { ... }  # user_id appears at path level, not here
      #     end
      #   end
      #
      # @example Marking multiple params
      #   route_param :user_id do
      #     route_param :post_id do
      #       path_params :user_id, :post_id
      #       get { ... }
      #     end
      #   end
      #
      # @param param_names [Array<Symbol,String>] Names of params to move to path level
      #
      def path_params(*param_names)
        # Store in route_setting so it's accessible via route.settings
        route_setting :path_level_param_names, param_names.map(&:to_s)
      end
    end
  end
end

# Include the path_params DSL in Grape's API classes
# This makes it available inside namespace blocks and at the API class level
Grape::API.extend(GrapeSwagger::Endpoint::PathParamsExtension)
Grape::API::Instance.extend(GrapeSwagger::Endpoint::PathParamsExtension)
