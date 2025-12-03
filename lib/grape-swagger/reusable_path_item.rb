# frozen_string_literal: true

module GrapeSwagger
  # ReusablePathItem allows defining reusable path item components for OpenAPI 3.1.0.
  #
  # Path items can be defined once and referenced from multiple paths using $ref.
  # This is useful for standard CRUD operations or common path patterns.
  #
  # @example Define a reusable path item
  #   class UserItemPath < GrapeSwagger::ReusablePathItem
  #     summary 'User Item Operations'
  #     description 'Standard CRUD operations for a single user'
  #
  #     parameter :id, in: :path, type: Integer, required: true, desc: 'User ID'
  #
  #     get_operation do
  #       summary 'Get user by ID'
  #       response 200, description: 'User found', model: UserEntity
  #       response 404, description: 'User not found'
  #     end
  #
  #     put_operation do
  #       summary 'Update user'
  #       request_body 'application/json', schema: UpdateUserEntity
  #       response 200, description: 'User updated', model: UserEntity
  #     end
  #
  #     delete_operation do
  #       summary 'Delete user'
  #       response 204, description: 'User deleted'
  #     end
  #   end
  #
  # @example Reference a path item in Grape API
  #   class UsersAPI < Grape::API
  #     # Use path_ref to reference a reusable path item
  #     route_setting :path_ref, :UserItemPath
  #     resource :users do
  #       route_param :id do
  #         # Operations are defined in UserItemPath
  #       end
  #     end
  #   end
  #
  class ReusablePathItem
    class << self
      def inherited(subclass)
        super
        # Defer registration to allow DSL to execute
        TracePoint.new(:end, :b_return) do |tp|
          if tp.self == subclass
            begin
              GrapeSwagger::ComponentsRegistry.register_path_item(subclass)
            rescue ArgumentError
              # Silently skip if we can't determine the name yet
            end
            tp.disable
          end
        end.enable
      end

      # DSL Methods

      # Set a custom component name (optional, defaults to class name)
      def component_name(val = nil)
        return @component_name if val.nil?

        @component_name = val
      end

      # Set summary for the path item
      def summary(val)
        @summary = val
      end

      # Set description for the path item
      def description(val)
        @description = val
      end

      # Define path-level parameters
      def parameter(name, opts = {})
        @parameters ||= []
        @parameters << opts.merge(name: name)
      end

      # Define path-level servers (operation-level override)
      def servers(*server_list)
        @servers = server_list.flatten
      end

      # Operation definitions using blocks
      def get_operation(&block)
        @operations ||= {}
        @operations[:get] = OperationBuilder.new.tap { |b| b.instance_eval(&block) }
      end

      def post_operation(&block)
        @operations ||= {}
        @operations[:post] = OperationBuilder.new.tap { |b| b.instance_eval(&block) }
      end

      def put_operation(&block)
        @operations ||= {}
        @operations[:put] = OperationBuilder.new.tap { |b| b.instance_eval(&block) }
      end

      def patch_operation(&block)
        @operations ||= {}
        @operations[:patch] = OperationBuilder.new.tap { |b| b.instance_eval(&block) }
      end

      def delete_operation(&block)
        @operations ||= {}
        @operations[:delete] = OperationBuilder.new.tap { |b| b.instance_eval(&block) }
      end

      def options_operation(&block)
        @operations ||= {}
        @operations[:options] = OperationBuilder.new.tap { |b| b.instance_eval(&block) }
      end

      def head_operation(&block)
        @operations ||= {}
        @operations[:head] = OperationBuilder.new.tap { |b| b.instance_eval(&block) }
      end

      def trace_operation(&block)
        @operations ||= {}
        @operations[:trace] = OperationBuilder.new.tap { |b| b.instance_eval(&block) }
      end

      # Convert to OpenAPI path item object
      def to_openapi
        result = {}

        result[:summary] = @summary if @summary
        result[:description] = @description if @description
        result[:parameters] = build_parameters if @parameters && !@parameters.empty?
        result[:servers] = @servers if @servers && !@servers.empty?

        # Add operations
        @operations&.each do |method, builder|
          result[method] = builder.to_openapi
        end

        result.compact
      end

      private

      def build_parameters
        @parameters.map do |param|
          {
            name: param[:name].to_s,
            in: (param[:in] || :query).to_s,
            required: param[:required] || false,
            description: param[:desc] || param[:description],
            schema: build_param_schema(param)
          }.compact
        end
      end

      def build_param_schema(param)
        schema = {}
        schema[:type] = type_to_openapi(param[:type]) if param[:type]
        schema[:format] = param[:format] if param[:format]
        schema[:enum] = param[:values] if param[:values]
        schema[:default] = param[:default] if param.key?(:default)
        schema
      end

      def type_to_openapi(type)
        case type.to_s
        when 'Integer', 'Fixnum', 'Bignum' then 'integer'
        when 'Float', 'BigDecimal' then 'number'
        when 'TrueClass', 'FalseClass', 'Virtus::Attribute::Boolean', 'Boolean' then 'boolean'
        when 'Array' then 'array'
        when 'Hash' then 'object'
        else 'string'
        end
      end
    end

    # Helper class to build operation objects within path items
    class OperationBuilder
      def initialize
        @responses = {}
        @parameters = []
        @tags = []
      end

      def summary(val)
        @summary = val
      end

      def description(val)
        @description = val
      end

      def operation_id(val)
        @operation_id = val
      end

      def tags(*tag_list)
        @tags = tag_list.flatten
      end

      def deprecated(val = true)
        @deprecated = val
      end

      def parameter(name, opts = {})
        @parameters << opts.merge(name: name)
      end

      def response(code, opts = {})
        @responses[code] = opts
      end

      def request_body(media_type, opts = {})
        @request_body ||= { content: {} }
        @request_body[:content][media_type] = opts
        @request_body[:required] = opts[:required] if opts.key?(:required)
        @request_body[:description] = opts[:description] if opts[:description]
      end

      def security(*schemes)
        @security = schemes.flatten
      end

      def to_openapi
        result = {}

        result[:summary] = @summary if @summary
        result[:description] = @description if @description
        result[:operationId] = @operation_id if @operation_id
        result[:tags] = @tags unless @tags.empty?
        result[:deprecated] = @deprecated if @deprecated
        result[:parameters] = build_parameters unless @parameters.empty?
        result[:requestBody] = build_request_body if @request_body
        result[:responses] = build_responses
        result[:security] = @security if @security

        result.compact
      end

      private

      def build_parameters
        @parameters.map do |param|
          {
            name: param[:name].to_s,
            in: (param[:in] || :query).to_s,
            required: param[:required] || false,
            description: param[:desc] || param[:description],
            schema: { type: 'string' } # Simplified; expand as needed
          }.compact
        end
      end

      def build_request_body
        body = {}
        body[:description] = @request_body[:description] if @request_body[:description]
        body[:required] = @request_body[:required] if @request_body.key?(:required)
        body[:content] = @request_body[:content].transform_values do |opts|
          result = {}
          result[:schema] = build_schema(opts[:schema]) if opts[:schema]
          result[:example] = opts[:example] if opts[:example]
          result.compact
        end
        body.compact
      end

      def build_responses
        @responses.transform_values do |opts|
          result = { description: opts[:description] || '' }
          if opts[:model]
            result[:content] = {
              'application/json' => {
                schema: build_schema(opts[:model])
              }
            }
          end
          result.compact
        end
      end

      def build_schema(model_or_schema)
        if model_or_schema.is_a?(Hash)
          model_or_schema
        elsif model_or_schema.is_a?(Class)
          # Reference to an entity/schema
          { '$ref' => "#/components/schemas/#{model_or_schema.name.split('::').last}" }
        else
          { '$ref' => "#/components/schemas/#{model_or_schema}" }
        end
      end
    end
  end
end
