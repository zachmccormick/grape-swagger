# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    module PathParamsExtension
      # DSL method to define path-level parameters that are shared across
      # all operations on a path (GET, POST, PUT, DELETE, etc.)
      #
      # @example
      #   namespace :users do
      #     path_params do
      #       requires :user_id, type: Integer, desc: 'User ID'
      #     end
      #
      #     route_param :user_id do
      #       get { ... }
      #       put { ... }
      #     end
      #   end
      #
      def path_params(&block)
        # Store the block for later doc generation
        namespace_setting :path_parameter_block, block

        # Apply to Grape params for runtime validation
        params(&block)
      end
    end
  end
end

# Extend Grape::API with the path_params DSL
# This makes it available in namespace contexts
Grape::API.extend(GrapeSwagger::Endpoint::PathParamsExtension)
