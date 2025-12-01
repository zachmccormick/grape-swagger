# frozen_string_literal: true

module GrapeSwagger
  module Endpoint
    module ParamsExtensions
      def ref(component_name)
        # Store reference for OpenAPI doc generation
        refs = (@api.route_setting(:parameter_refs) || []).dup
        refs << component_name.to_s
        @api.route_setting :parameter_refs, refs

        # Also apply the actual Grape parameter for runtime validation
        klass = GrapeSwagger::ComponentsRegistry.find_parameter!(component_name)
        openapi = klass.to_openapi

        # Convert OpenAPI schema to Grape param options
        grape_type = openapi_type_to_grape(openapi.dig(:schema, :type))
        grape_opts = {
          type: grape_type,
          desc: openapi[:description],
          default: openapi.dig(:schema, :default),
          documentation: { hidden: true } # Hide from swagger doc, use $ref instead
        }.compact

        if openapi[:required]
          requires openapi[:name].to_sym, **grape_opts
        else
          optional openapi[:name].to_sym, **grape_opts
        end
      end

      private

      def openapi_type_to_grape(type)
        case type.to_s
        when 'integer' then Integer
        when 'number' then Float
        when 'boolean' then Grape::API::Boolean
        when 'array' then Array
        else String
        end
      end
    end
  end
end

# Patch into Grape's params DSL
Grape::Validations::ParamsScope.include(GrapeSwagger::Endpoint::ParamsExtensions)
