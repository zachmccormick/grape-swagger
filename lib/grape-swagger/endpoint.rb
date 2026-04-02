# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/string/inflections'
require_relative 'request_param_parsers/headers'
require_relative 'request_param_parsers/route'
require_relative 'request_param_parsers/body'
require_relative 'token_owner_resolver'
require_relative 'openapi/version_constants'
require_relative 'openapi/errors'
require_relative 'openapi/version'
require_relative 'openapi/version_selector'
require_relative 'openapi/schema_resolver'
require_relative 'openapi/nullable_type_handler'
require_relative 'openapi/binary_data_encoder'
require_relative 'openapi/request_body_builder'
require_relative 'openapi/response_content_builder'
require_relative 'openapi/parameter_schema_wrapper'
require_relative 'openapi/callback_builder'
require_relative 'openapi/link_builder'

module Grape
  class Endpoint # rubocop:disable Metrics/ClassLength
    def content_types_for(target_class)
      content_types = (target_class.content_types || {}).values

      if content_types.empty?
        formats       = [target_class.format, target_class.default_format].compact.uniq
        formats       = GrapeSwagger::FORMATTER_DEFAULTS.keys if formats.empty?
        content_types = formats.filter_map { |f| GrapeSwagger::CONTENT_TYPE_DEFAULTS[f] }
      end

      content_types.uniq
    end

    # swagger spec2.0 related parts
    #
    # required keys for SwaggerObject
    def swagger_object(target_class, request, options)
      version = detect_openapi_version(options)

      if version&.openapi_3_1_0?
        openapi_3_1_object(target_class, request, options, version)
      else
        swagger_2_0_object(target_class, request, options)
      end
    end

    def swagger_2_0_object(target_class, request, options)
      object = {
        info: info_object(options[:info].merge(version: options[:doc_version])),
        swagger: '2.0',
        produces: options[:produces] || content_types_for(target_class),
        consumes: options[:consumes],
        authorizations: options[:authorizations],
        securityDefinitions: options[:security_definitions],
        security: options[:security],
        host: GrapeSwagger::DocMethods::OptionalObject.build(:host, options, request),
        basePath: GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options, request),
        schemes: options[:schemes].is_a?(String) ? [options[:schemes]] : options[:schemes]
      }

      GrapeSwagger::DocMethods::Extensions.add_extensions_to_root(options, object)
      object.delete_if { |_, value| value.blank? }
    end

    def openapi_3_1_object(target_class, request, options, version)
      security_schemes = transform_security_definitions(options[:security_definitions])

      object = {
        info: info_object(options[:info].merge(version: options[:doc_version])),
        openapi: '3.1.0',
        security: options[:security],
        host: GrapeSwagger::DocMethods::OptionalObject.build(:host, options, request),
        basePath: GrapeSwagger::DocMethods::OptionalObject.build(:base_path, options, request),
        schemes: options[:schemes].is_a?(String) ? [options[:schemes]] : options[:schemes]
      }

      # Add security schemes to components
      if security_schemes && !security_schemes.empty?
        object[:components] ||= {}
        object[:components][:securitySchemes] = security_schemes
      end

      GrapeSwagger::DocMethods::Extensions.add_extensions_to_root(options, object)
      object.delete_if { |_, value| value.blank? }
    end

    # Transform security definitions to OpenAPI 3.1.0 format using SecuritySchemeBuilder
    def transform_security_definitions(security_definitions)
      return nil if security_definitions.nil? || security_definitions.empty?

      security_definitions.each_with_object({}) do |(name, config), result|
        transformed = GrapeSwagger::OpenAPI::SecuritySchemeBuilder.build(config)
        result[name] = transformed if transformed
      end
    end

    # building info object
    def info_object(infos)
      result = {
        title: infos[:title] || 'API title',
        description: infos[:description],
        termsOfService: infos[:terms_of_service_url],
        contact: contact_object(infos),
        license: license_object(infos),
        version: infos[:version]
      }

      GrapeSwagger::DocMethods::Extensions.add_extensions_to_info(infos, result)

      result.delete_if { |_, value| value.blank? }
    end

    # sub-objects of info object
    # license
    def license_object(infos)
      {
        name: infos.delete(:license),
        url: infos.delete(:license_url)
      }.delete_if { |_, value| value.blank? }
    end

    # contact
    def contact_object(infos)
      {
        name: infos.delete(:contact_name),
        email: infos.delete(:contact_email),
        url: infos.delete(:contact_url)
      }.delete_if { |_, value| value.blank? }
    end

    # building path and definitions objects
    def path_and_definition_objects(namespace_routes, options)
      @paths = {}
      @definitions = {}
      add_definitions_from options[:models]
      namespace_routes.each_value do |routes|
        path_item(routes, options)
      end

      [@paths, @definitions]
    end

    def add_definitions_from(models)
      return if models.nil?

      models.each { |x| expose_params_from_model(x) }
    end

    # path object
    def path_item(routes, options)
      # First pass: collect all path-level param names across all routes for this path
      # We need to do this before processing routes so we can build params correctly
      path_level_params_by_path = {}
      path_refs_by_path = {}
      path_servers_by_path = {}

      # First pass: collect path-level settings from all routes
      routes.each do |route|
        _item, path = GrapeSwagger::DocMethods::PathString.build(route, options)

        # Check for path_ref setting (OpenAPI 3.1.0 feature)
        path_refs_by_path[path.to_s] = route.settings[:path_ref] if route.settings[:path_ref]

        # Check for path_servers setting (OpenAPI 3.1.0 feature)
        path_servers_by_path[path.to_s] = route.settings[:path_servers] if route.settings[:path_servers]

        path_param_names = collect_path_param_names(route)
        next if path_param_names.empty?

        path_level_params_by_path[path.to_s] ||= Set.new
        path_level_params_by_path[path.to_s].merge(path_param_names)
      end

      # Second pass: build path items using collected settings
      routes.each do |route|
        next if hidden?(route, options)

        @item, path = GrapeSwagger::DocMethods::PathString.build(route, options)

        # Handle path_ref for OpenAPI 3.1.0 (entire path becomes a $ref)
        if path_refs_by_path[path.to_s] && !@paths.key?(path.to_s)
          path_ref_name = path_refs_by_path[path.to_s]
          # Verify the path item component exists
          GrapeSwagger::ComponentsRegistry.find_path_item!(path_ref_name)
          @paths[path.to_s] = { '$ref' => "#/components/pathItems/#{path_ref_name}" }
          next
        end

        # Skip if this path is already a $ref
        next if @paths[path.to_s].is_a?(Hash) && @paths[path.to_s].key?('$ref')

        @entity = route.entity || route.options[:success]

        # Pass path-level param names to method_object so params can be built before filtering
        verb, method_object, path_level_params = method_object_with_path_params(
          route, options, path, path_level_params_by_path[path.to_s]&.to_a || []
        )

        if @paths.key?(path.to_s)
          @paths[path.to_s][verb] = method_object
        else
          @paths[path.to_s] = { verb => method_object }

          # Add path-level parameters if we collected any
          @paths[path.to_s][:parameters] = path_level_params if path_level_params&.any?

          # Add path-level servers if specified (OpenAPI 3.1.0 feature)
          @paths[path.to_s][:servers] = path_servers_by_path[path.to_s] if path_servers_by_path[path.to_s]
        end

        GrapeSwagger::DocMethods::Extensions.add(@paths[path.to_s], @definitions, route)
      end
    end

    def method_object(route, options, path)
      method = {}
      method[:summary]     = summary_object(route)
      method[:description] = description_object(route)
      method[:produces]    = produces_object(route, options[:produces] || options[:format])
      method[:consumes]    = consumes_object(route, options[:consumes] || options[:format])
      method[:parameters]  = params_object(route, options, path, method[:consumes])
      method[:security]    = security_object(route)
      method[:responses]   = response_object(route, options)
      method[:tags]        = route.options.fetch(:tags, tag_object(route, path))
      method[:operationId] = GrapeSwagger::DocMethods::OperationId.build(route, path)
      method[:deprecated] = deprecated_object(route)
      method[:servers] = servers_object(route)

      # For OpenAPI 3.1.0, build requestBody from body parameters
      apply_request_body!(method, route, options)

      # For OpenAPI 3.1.0, wrap remaining parameter schemas
      apply_parameter_schema_wrapping!(method, options)

      # For OpenAPI 3.1.0, wrap response schemas in content objects
      apply_response_content!(method, options)

      # For OpenAPI 3.1.0, add callbacks if present in route options
      apply_callbacks!(method, route, options)

      # For OpenAPI 3.1.0, add links to responses if present in route options
      apply_links!(method, route, options)

      method.delete_if { |_, value| value.nil? }

      [route.request_method.downcase.to_sym, method]
    end

    # Like method_object but also returns path-level parameters separately
    # @param route [Grape::Router::Route] The route
    # @param options [Hash] Documentation options
    # @param path [String] The path string
    # @param path_level_param_names [Array<String>] Names of params that should be at path level
    # @return [Array] [verb, method_object, path_level_params]
    def method_object_with_path_params(route, options, path, path_level_param_names)
      return [*method_object(route, options, path), nil] if path_level_param_names.empty?

      # Build all params first (before filtering)
      consumes = consumes_object(route, options[:consumes] || options[:format])
      all_params = params_object_unfiltered(route, options, path, consumes)

      # Extract path-level params
      path_level_params = all_params&.select do |p|
        path_level_param_names.include?(p[:name]&.to_s)
      end

      # Filter out path-level params from operation params
      operation_params = all_params&.reject do |p|
        path_level_param_names.include?(p[:name]&.to_s)
      end

      # Build the rest of method object
      method = {}
      method[:summary]     = summary_object(route)
      method[:description] = description_object(route)
      method[:produces]    = produces_object(route, options[:produces] || options[:format])
      method[:consumes]    = consumes
      method[:parameters]  = finalize_params(operation_params, route, path)
      method[:security]    = security_object(route)
      method[:responses]   = response_object(route, options)
      method[:tags]        = route.options.fetch(:tags, tag_object(route, path))
      method[:operationId] = GrapeSwagger::DocMethods::OperationId.build(route, path)
      method[:deprecated] = deprecated_object(route)
      method[:servers] = servers_object(route)

      # Handle OpenAPI 3.1.0 specifics
      version = detect_openapi_version(options)
      if version&.openapi_3_1_0?
        # Wrap parameters in schema objects
        if method[:parameters]
          method[:parameters] = method[:parameters].map do |param|
            GrapeSwagger::OpenAPI::ParameterSchemaWrapper.wrap(param, version)
          end
        end

        # Wrap path-level params in schema objects too
        if path_level_params&.any?
          path_level_params = path_level_params.map do |param|
            GrapeSwagger::OpenAPI::ParameterSchemaWrapper.wrap(param, version)
          end
        end

        # Extract body parameters before removing them
        body_params = extract_body_params(method[:parameters])

        # Build requestBody
        request_body = GrapeSwagger::OpenAPI::RequestBodyBuilder.build(
          body_params,
          route.request_method,
          method[:consumes],
          version
        )
        method[:requestBody] = request_body if request_body

        # Remove body/formData parameters
        if method[:parameters]
          method[:parameters] = method[:parameters].reject { |p| %w[body formData].include?(p[:in]) }
          method.delete(:parameters) if method[:parameters].empty?
        end

        # Wrap response schemas
        if method[:responses]
          method[:responses] = method[:responses].transform_values do |response|
            GrapeSwagger::OpenAPI::ResponseContentBuilder.build(response, version, method[:produces])
          end
        end

        # Add callbacks
        if route.options[:callbacks]
          callbacks = GrapeSwagger::OpenAPI::CallbackBuilder.build(route.options[:callbacks], version)
          method[:callbacks] = callbacks if callbacks
        end

        # Add links
        route.options[:links]&.each do |status_code, links_for_status|
          response_key = method[:responses]&.key?(status_code) ? status_code : status_code.to_s
          next unless method[:responses] && method[:responses][response_key]

          built_links = GrapeSwagger::OpenAPI::LinkBuilder.build(links_for_status, version)
          method[:responses][response_key][:links] = built_links if built_links
        end

        method.delete(:produces)
        method.delete(:consumes)
      end

      method.delete_if { |_, value| value.nil? }

      [route.request_method.downcase.to_sym, method, path_level_params]
    end

    # Extract parameters that should go into requestBody
    # In OpenAPI 3.x, both 'body' and 'formData' parameters go into requestBody
    def extract_body_params(parameters)
      return [] unless parameters.is_a?(Array)

      parameters.select { |p| p.is_a?(Hash) && %w[body formData].include?(p[:in]) }
    end

    def deprecated_object(route)
      route.options[:deprecated] if route.options.key?(:deprecated)
    end

    def servers_object(route)
      route.options[:servers] if route.options.key?(:servers)
    end

    # Applies requestBody for OpenAPI 3.1.0 endpoints
    # Extracts body params, builds requestBody, and removes body params from parameters
    def apply_request_body!(method, route, options)
      version = detect_openapi_version(options)
      return unless version&.openapi_3_1_0?
      return unless method[:parameters].is_a?(Array)

      # Build requestBody from body parameters
      request_body = GrapeSwagger::OpenAPI::RequestBodyBuilder.build(
        method[:parameters],
        route.request_method,
        method[:consumes],
        version
      )

      if request_body
        method[:requestBody] = request_body

        # Remove body parameters from parameters array for OpenAPI 3.1.0
        method[:parameters] = method[:parameters].reject { |p| %w[body formData].include?(p[:in]) }
        method.delete(:parameters) if method[:parameters].empty?
      end
    end

    # Applies parameter schema wrapping for OpenAPI 3.1.0
    # Wraps remaining non-body parameter type/format/constraints into schema objects
    def apply_parameter_schema_wrapping!(method, options)
      version = detect_openapi_version(options)
      return unless version&.openapi_3_1_0?
      return unless method[:parameters].is_a?(Array)

      method[:parameters] = method[:parameters].map do |param|
        GrapeSwagger::OpenAPI::ParameterSchemaWrapper.wrap(param, version)
      end
    end

    # Applies response content wrapping for OpenAPI 3.1.0
    # Transforms each response via ResponseContentBuilder
    def apply_response_content!(method, options)
      version = detect_openapi_version(options)
      return unless version&.openapi_3_1_0?
      return unless method[:responses].is_a?(Hash)

      method[:responses] = method[:responses].transform_values do |response|
        GrapeSwagger::OpenAPI::ResponseContentBuilder.build(
          response,
          version,
          method[:produces]
        )
      end
    end

    # Applies callbacks for OpenAPI 3.1.0 endpoints
    # Reads callback definitions from route options and builds callbacks object
    def apply_callbacks!(method, route, options)
      version = detect_openapi_version(options)
      return unless version&.openapi_3_1_0?
      return unless route.options[:callbacks]

      callbacks = GrapeSwagger::OpenAPI::CallbackBuilder.build(route.options[:callbacks], version)
      method[:callbacks] = callbacks if callbacks
    end

    # Applies links for OpenAPI 3.1.0 endpoints
    # Reads link definitions from route options and attaches to corresponding responses
    def apply_links!(method, route, options)
      version = detect_openapi_version(options)
      return unless version&.openapi_3_1_0?
      return unless route.options[:links]
      return unless method[:responses].is_a?(Hash)

      route.options[:links].each do |status_code, links_for_status|
        # Check both integer and string keys for the status code
        response_key = method[:responses].key?(status_code) ? status_code : status_code.to_s
        next unless method[:responses][response_key]

        built_links = GrapeSwagger::OpenAPI::LinkBuilder.build(links_for_status, version)
        method[:responses][response_key][:links] = built_links if built_links
      end
    end

    # Detect the OpenAPI version from options
    # Returns nil for Swagger 2.0 (default behavior)
    def detect_openapi_version(options)
      GrapeSwagger::OpenAPI::VersionSelector.build_spec(options)
    rescue StandardError
      nil
    end

    def security_object(route)
      route.options[:security] if route.options.key?(:security)
    end

    def summary_object(route)
      summary = route.options[:desc] if route.options.key?(:desc)
      summary = route.description if route.description.present? && route.options.key?(:detail)
      summary = route.options[:summary] if route.options.key?(:summary)

      summary
    end

    def description_object(route)
      description = route.description if route.description.present?
      description = route.options[:detail] if route.options.key?(:detail)

      description
    end

    def produces_object(route, format)
      return ['application/octet-stream'] if file_response?(route.attributes.success) &&
                                             !route.attributes.produces.present?

      mime_types = GrapeSwagger::DocMethods::ProducesConsumes.call(format)

      route_mime_types = %i[formats content_types produces].map do |producer|
        possible = route.options[producer]
        GrapeSwagger::DocMethods::ProducesConsumes.call(possible) if possible.present?
      end.flatten.compact.uniq

      route_mime_types.present? ? route_mime_types : mime_types
    end

    SUPPORTS_CONSUMES = %i[post put patch].freeze

    def consumes_object(route, format)
      return unless SUPPORTS_CONSUMES.include?(route.request_method.downcase.to_sym)

      GrapeSwagger::DocMethods::ProducesConsumes.call(route.settings.dig(:description, :consumes) || format)
    end

    def params_object(route, options, path, consumes)
      parameters = build_request_params(route, options).each_with_object([]) do |(param, value), memo|
        next if hidden_parameter?(value)

        value = { required: false }.merge(value) if value.is_a?(Hash)
        _, value = default_type([[param, value]]).first if value == ''

        if value.dig(:documentation, :type)
          expose_params(value[:documentation][:type])
        elsif value[:type]
          expose_params(value[:type])
        end
        memo << GrapeSwagger::DocMethods::ParseParams.call(param, value, path, route, @definitions, consumes)
      end

      if GrapeSwagger::DocMethods::MoveParams.can_be_moved?(route.request_method, parameters)
        parameters = GrapeSwagger::DocMethods::MoveParams.to_definition(path, parameters, route, @definitions)
      end

      GrapeSwagger::DocMethods::FormatData.to_format(parameters)

      # Inject $ref entries for parameter references
      parameter_refs = route.settings.dig(:description, :parameter_refs) ||
                       route.settings.dig(:parameter_refs)
      if parameter_refs.is_a?(Array) && parameter_refs.any?
        parameters ||= []
        parameter_refs.each do |ref_name|
          parameters.unshift({ '$ref' => "#/components/parameters/#{ref_name}" })
        end
      end

      parameters.presence
    end

    # Build params without filtering out path-level params or applying MoveParams/FormatData
    # Used by method_object_with_path_params to get all params first
    def params_object_unfiltered(route, options, path, consumes)
      parameters = build_request_params(route, options).each_with_object([]) do |(param, value), memo|
        next if hidden_parameter?(value)

        value = { required: false }.merge(value) if value.is_a?(Hash)
        _, value = default_type([[param, value]]).first if value == ''

        if value.dig(:documentation, :type)
          expose_params(value[:documentation][:type])
        elsif value[:type]
          expose_params(value[:type])
        end
        memo << GrapeSwagger::DocMethods::ParseParams.call(param, value, path, route, @definitions, consumes)
      end

      # Add parameter references from route settings
      parameter_refs = route.settings.dig(:description, :parameter_refs) ||
                       route.settings.dig(:parameter_refs)
      if parameter_refs.is_a?(Array) && parameter_refs.any?
        parameter_refs.each do |ref_name|
          parameters << { '$ref' => "#/components/parameters/#{ref_name}" }
        end
      end

      parameters.presence
    end

    # Finalize params by applying MoveParams and FormatData
    def finalize_params(parameters, route, path)
      return nil if parameters.nil? || parameters.empty?

      if GrapeSwagger::DocMethods::MoveParams.can_be_moved?(route.request_method, parameters)
        parameters = GrapeSwagger::DocMethods::MoveParams.to_definition(path, parameters, route, @definitions)
      end

      GrapeSwagger::DocMethods::FormatData.to_format(parameters)

      parameters.presence
    end

    # Collect names of parameters defined at path level via path_params DSL
    #
    # We look for :path_level_param_names in route settings which is set by
    # the path_params DSL method using route_setting
    #
    # @param route [Grape::Router::Route] The route
    # @return [Array<String>] Parameter names defined via path_params
    def collect_path_param_names(route)
      path_level_names = route.settings[:path_level_param_names]
      return [] unless path_level_names.is_a?(Array)

      path_level_names.flatten.map(&:to_s)
    end

    def response_object(route, options)
      codes(route).each_with_object({}) do |value, memo|
        value[:message] ||= ''

        # Handle Symbol models as response component references
        if value[:model].is_a?(Symbol) && response_component_registered?(value[:model])
          memo[value[:code]] = { '$ref' => "#/components/responses/#{value[:model]}" }
          next
        end

        memo[value[:code]] = { description: value[:message] ||= '' } unless memo[value[:code]].present?
        memo[value[:code]][:headers] = value[:headers] if value[:headers]

        next build_file_response(memo[value[:code]]) if file_response?(value[:model])

        next build_delete_response(memo, value) if delete_response?(memo, route, value)
        next build_response_for_type_parameter(memo, route, value, options) if value[:type]

        # Explicitly request no model with { model: '' }
        next if value[:model] == ''

        response_model = value[:model] ? expose_params_from_model(value[:model]) : @item
        next unless @definitions[response_model]
        next if response_model.start_with?('Swagger_doc')

        @definitions[response_model][:description] ||= "#{response_model} model"
        build_memo_schema(memo, route, value, response_model, options)
        memo[value[:code]][:examples] = value[:examples] if value[:examples]
      end
    end

    def codes(route)
      http_codes_from_route(route).map do |x|
        x.is_a?(Array) ? { code: x[0], message: x[1], model: x[2], examples: x[3], headers: x[4] } : x
      end
    end

    def success_code?(code)
      status = code.is_a?(Array) ? code.first : code[:code]
      status.between?(200, 299)
    end

    def http_codes_from_route(route)
      if route.http_codes.is_a?(Array) && route.http_codes.any? { |code| success_code?(code) }
        route.http_codes.clone
      else
        success_codes_from_route(route) + default_code_from_route(route) +
          (route.http_codes || route.options[:failure] || [])
      end
    end

    def success_codes_from_route(route)
      if @entity.is_a?(Array)
        return @entity.map do |entity|
          success_code_from_entity(route, entity)
        end
      end

      [success_code_from_entity(route, @entity)]
    end

    def tag_object(route, path)
      version = GrapeSwagger::DocMethods::Version.get(route)
      version = Array(version)
      prefix = route.prefix.to_s.split('/').reject(&:empty?)
      Array(
        path.split('{')[0].split('/').reject(&:empty?).delete_if do |i|
          prefix.include?(i) || version.map(&:to_s).include?(i)
        end.first
      ).presence
    end

    private

    def default_code_from_route(route)
      entity = route.options[:default_response]
      return [] if entity.nil?

      default_code = { code: 'default', message: 'Default Response' }
      if entity.is_a?(Hash)
        default_code[:message] = entity[:message] || default_code[:message]
        default_code[:model] = entity[:model] if entity[:model].present?
      else
        default_code[:model] = entity
      end

      [default_code]
    end

    def build_delete_response(memo, value)
      memo[204] = memo.delete(200)
      value[:code] = 204
    end

    def delete_response?(memo, route, value)
      memo.key?(200) && route.request_method == 'DELETE' && value[:model].nil?
    end

    def build_memo_schema(memo, route, value, response_model, options)
      if memo[value[:code]][:schema] && value[:as]
        memo[value[:code]][:schema][:properties].merge!(build_reference(route, value, response_model, options))

        if value[:required]
          memo[value[:code]][:schema][:required] ||= []
          memo[value[:code]][:schema][:required] << value[:as].to_s
        end

      elsif value[:as]
        memo[value[:code]][:schema] = {
          type: :object,
          properties: build_reference(route, value, response_model, options)
        }
        memo[value[:code]][:schema][:required] = [value[:as].to_s] if value[:required]
      else
        memo[value[:code]][:schema] = build_reference(route, value, response_model, options)
      end
    end

    def build_response_for_type_parameter(memo, _route, value, _options)
      type, format = prepare_type_and_format(value)

      if memo[value[:code]].include?(:schema) && value.include?(:as)
        memo[value[:code]][:schema][:properties].merge!(value[:as] => { type: type, format: format }.compact)
      elsif value.include?(:as)
        memo[value[:code]][:schema] =
          { type: :object, properties: { value[:as] => { type: type, format: format }.compact } }
      else
        memo[value[:code]][:schema] = { type: type }
      end
    end

    def prepare_type_and_format(value)
      data_type = GrapeSwagger::DocMethods::DataType.call(value[:type])

      if GrapeSwagger::DocMethods::DataType.primitive?(data_type)
        GrapeSwagger::DocMethods::DataType.mapping(data_type)
      else
        data_type
      end
    end

    def build_reference(route, value, response_model, settings)
      # TODO: proof that the definition exist, if model isn't specified
      reference = if value.key?(:as)
                    { value[:as] => build_reference_hash(response_model) }
                  else
                    build_reference_hash(response_model)
                  end
      return reference unless value[:code] == 'default' || value[:code] < 300

      if value.key?(:as) && value.key?(:is_array)
        reference[value[:as]] = build_reference_array(reference[value[:as]])
      elsif route.options[:is_array]
        reference = build_reference_array(reference)
      end

      build_root(route, reference, response_model, settings)
    end

    def build_reference_hash(response_model)
      { '$ref' => "#/definitions/#{response_model}" }
    end

    def build_reference_array(reference)
      { type: 'array', items: reference }
    end

    def build_root(route, reference, response_model, settings)
      default_root = response_model.underscore
      default_root = default_root.pluralize if route.options[:is_array]
      case route.settings.dig(:swagger, :root)
      when true
        { type: 'object', properties: { default_root => reference } }
      when false
        reference
      when nil
        settings[:add_root] ? { type: 'object', properties: { default_root => reference } } : reference
      else
        { type: 'object', properties: { route.settings.dig(:swagger, :root) => reference } }
      end
    end

    def file_response?(value)
      value.to_s.casecmp('file').zero?
    end

    def build_file_response(memo)
      memo['schema'] = { type: 'file' }
    end

    def build_request_params(route, settings)
      GrapeSwagger.request_param_parsers.each_with_object({}) do |parser_klass, accum|
        params = parser_klass.parse(
          route,
          accum,
          settings,
          self
        )
        accum.merge!(params.stringify_keys)
      end
    end

    def default_type(params)
      default_param_type = { required: true, type: 'Integer' }
      params.each { |param| param[-1] = param.last.empty? ? default_param_type : param.last }
    end

    def expose_params(value)
      if value.is_a?(Class) && GrapeSwagger.model_parsers.find(value)
        expose_params_from_model(value)
      elsif value.is_a?(String)
        begin
          expose_params(Object.const_get(value.gsub(/\[|\]/, ''))) # try to load class from its name
        rescue NameError
          nil
        end
      end
    end

    def expose_params_from_model(model)
      model = model.constantize if model.is_a?(String)
      model_name = model_name(model)

      return model_name if @definitions.key?(model_name)

      @definitions[model_name] = nil

      parser = GrapeSwagger.model_parsers.find(model)
      raise GrapeSwagger::Errors::UnregisteredParser, "No parser registered for #{model_name}." unless parser

      parsed_response = parser.new(model, self).call

      @definitions[model_name] =
        GrapeSwagger::DocMethods::BuildModelDefinition.parse_params_from_model(parsed_response, model, model_name)

      model_name
    end

    def model_name(name)
      GrapeSwagger::DocMethods::DataType.parse_entity_name(name)
    end

    def hidden?(route, options)
      route_hidden = route.settings.try(:[], :swagger).try(:[], :hidden)
      route_hidden = route.options[:hidden] if route.options.key?(:hidden)
      return route_hidden unless route_hidden.is_a?(Proc)

      return route_hidden.call unless options[:token_owner]

      token_owner = GrapeSwagger::TokenOwnerResolver.resolve(self, options[:token_owner])
      GrapeSwagger::TokenOwnerResolver.evaluate_proc(route_hidden, token_owner)
    end

    def response_component_registered?(name)
      GrapeSwagger::ComponentsRegistry.responses.key?(name.to_s)
    end

    def hidden_parameter?(value)
      return false if value[:required]

      if value.dig(:documentation, :hidden).is_a?(Proc)
        value.dig(:documentation, :hidden).call
      else
        value.dig(:documentation, :hidden)
      end
    end

    def success_code_from_entity(route, entity)
      default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym]
      if entity.is_a?(Hash)
        default_code[:code] = entity[:code] if entity[:code].present?
        default_code[:model] = entity[:model] if entity[:model].present?
        default_code[:message] = entity[:message] || route.description || default_code[:message].sub('{item}', @item)
        default_code[:examples] = entity[:examples] if entity[:examples]
        default_code[:headers] = entity[:headers] if entity[:headers]
        default_code[:as] = entity[:as] if entity[:as]
        default_code[:is_array] = entity[:is_array] if entity[:is_array]
        default_code[:required] = entity[:required] if entity[:required]
        default_code[:type] = entity[:type] if entity[:type]
      else
        default_code = GrapeSwagger::DocMethods::StatusCodes.get[route.request_method.downcase.to_sym]
        default_code[:model] = entity if entity
        default_code[:message] = route.description || default_code[:message].sub('{item}', @item)
      end

      default_code
    end
  end
end
