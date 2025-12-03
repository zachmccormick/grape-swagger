# frozen_string_literal: true

require 'grape-swagger/doc_methods/status_codes'
require 'grape-swagger/doc_methods/produces_consumes'
require 'grape-swagger/doc_methods/data_type'
require 'grape-swagger/doc_methods/extensions'
require 'grape-swagger/doc_methods/format_data'
require 'grape-swagger/doc_methods/operation_id'
require 'grape-swagger/doc_methods/optional_object'
require 'grape-swagger/doc_methods/path_string'
require 'grape-swagger/doc_methods/tag_name_description'
require 'grape-swagger/doc_methods/parse_params'
require 'grape-swagger/doc_methods/move_params'
require 'grape-swagger/doc_methods/build_model_definition'
require 'grape-swagger/doc_methods/version'

module GrapeSwagger
  module DocMethods
    DEFAULTS =
      {
        info: {},
        models: [],
        doc_version: '0.0.1',
        target_class: nil,
        mount_path: '/swagger_doc',
        host: nil,
        base_path: nil,
        add_base_path: false,
        add_version: true,
        add_root: false,
        hide_documentation_path: true,
        format: :json,
        authorizations: nil,
        security_definitions: nil,
        security: nil,
        api_documentation: { desc: 'Swagger compatible API description' },
        specific_api_documentation: { desc: 'Swagger compatible API description for specific API' },
        endpoint_auth_wrapper: nil,
        swagger_endpoint_guard: nil,
        token_owner: nil
      }.freeze

    FORMATTER_METHOD = %i[format default_format default_error_formatter].freeze

    def self.output_path_definitions(combi_routes, endpoint, target_class, options)
      output = endpoint.swagger_object(
        target_class,
        endpoint.request,
        options
      )

      paths, definitions   = endpoint.path_and_definition_objects(combi_routes, options)
      tags                 = tags_from(paths, options)

      output[:tags]        = tags unless tags.empty? || paths.blank?
      output[:paths]       = paths unless paths.blank?

      # For OpenAPI 3.x, place schemas in components/schemas instead of definitions
      if output[:openapi]&.start_with?('3.')
        unless definitions.blank?
          output[:components] ||= {}
          output[:components][:schemas] = definitions
        end
        # Transform all $ref paths from #/definitions/ to #/components/schemas/
        transform_definition_refs!(output)
        # Transform type: file to type: string, format: binary
        transform_file_types!(output)
        # Transform Swagger 2.0 style discriminators to OpenAPI 3.1.0 format
        if output[:components] && output[:components][:schemas]
          version = GrapeSwagger::OpenAPI::Version.new(output[:openapi])
          GrapeSwagger::OpenAPI::DiscriminatorTransformer.transform(output[:components][:schemas], version)
          # Transform nullable: true to type arrays for OpenAPI 3.1.0
          transform_nullable_types!(output[:components][:schemas], version)
          # Transform format: binary/byte to contentEncoding/contentMediaType for OpenAPI 3.1.0
          transform_binary_formats!(output[:components][:schemas], version)
        end
      else
        output[:definitions] = definitions unless definitions.blank?
      end

      output
    end

    # Recursively transform all $ref paths from #/definitions/ to #/components/schemas/
    def self.transform_definition_refs!(obj)
      case obj
      when Hash
        obj.each do |key, value|
          if key == '$ref' && value.is_a?(String) && value.start_with?('#/definitions/')
            obj[key] = value.sub('#/definitions/', '#/components/schemas/')
          else
            transform_definition_refs!(value)
          end
        end
      when Array
        obj.each { |item| transform_definition_refs!(item) }
      end
    end

    # Recursively transform nullable: true to type arrays for OpenAPI 3.1.0
    # JSON Schema 2020-12 uses type: ['string', 'null'] instead of nullable: true
    def self.transform_nullable_types!(schemas, version)
      return unless version.openapi_3_1_0?

      schemas.each_value do |schema|
        transform_nullable_in_schema!(schema, version)
      end
    end

    def self.transform_nullable_in_schema!(obj, version)
      case obj
      when Hash
        # Check if this hash has nullable: true
        nullable_key = if obj.key?(:nullable)
                         :nullable
                       else
                         (obj.key?('nullable') ? 'nullable' : nil)
                       end

        if nullable_key && obj[nullable_key] == true
          # Remove nullable
          obj.delete(nullable_key)

          # Get the type key
          type_key = if obj.key?(:type)
                       :type
                     else
                       (obj.key?('type') ? 'type' : nil)
                     end

          # Add 'null' to type array
          if type_key && obj[type_key]
            current_type = obj[type_key]
            types = Array(current_type)
            types << 'null' unless types.include?('null')
            obj[type_key] = types.uniq
          end
        end

        # Recurse into nested hashes
        obj.each_value { |value| transform_nullable_in_schema!(value, version) }
      when Array
        obj.each { |item| transform_nullable_in_schema!(item, version) }
      end
    end

    # Transform format: binary/byte to contentEncoding/contentMediaType for OpenAPI 3.1.0
    def self.transform_binary_formats!(schemas, version)
      return unless version.openapi_3_1_0?

      schemas.each_value do |schema|
        transform_binary_in_schema!(schema, version)
      end
    end

    # Binary format mappings
    BINARY_ENCODINGS = {
      'binary' => {
        contentEncoding: 'base64',
        contentMediaType: 'application/octet-stream'
      },
      'byte' => {
        contentEncoding: 'base64'
      }
    }.freeze

    def self.transform_binary_in_schema!(obj, version)
      case obj
      when Hash
        # Check if this hash has format: binary or format: byte
        format_key = if obj.key?(:format)
                       :format
                     else
                       (obj.key?('format') ? 'format' : nil)
                     end

        if format_key
          format_value = obj[format_key]&.to_s
          if BINARY_ENCODINGS.key?(format_value)
            # Remove format
            obj.delete(format_key)
            # Add contentEncoding/contentMediaType
            encoding = BINARY_ENCODINGS[format_value]
            obj[:contentEncoding] = encoding[:contentEncoding]
            obj[:contentMediaType] = encoding[:contentMediaType] if encoding[:contentMediaType]
          end
        end

        # Recurse into nested hashes
        obj.each_value { |value| transform_binary_in_schema!(value, version) }
      when Array
        obj.each { |item| transform_binary_in_schema!(item, version) }
      end
    end

    # Recursively transform type: file to type: string, format: binary for OpenAPI 3.x
    def self.transform_file_types!(obj)
      case obj
      when Hash
        # Handle both symbol and string keys
        type_key = if obj.key?(:type)
                     :type
                   else
                     (obj.key?('type') ? 'type' : nil)
                   end
        if type_key && obj[type_key] == 'file'
          obj[type_key] = 'string'
          format_key = obj.key?(:format) ? :format : 'format'
          obj[format_key] = 'binary'
        end
        obj.each_value { |value| transform_file_types!(value) }
      when Array
        obj.each { |item| transform_file_types!(item) }
      end
    end

    def self.tags_from(paths, options)
      tags = GrapeSwagger::DocMethods::TagNameDescription.build(paths)

      if options[:tags]
        names = options[:tags].map { |t| t[:name] }
        tags.reject! { |t| names.include?(t[:name]) }
        # Normalize tag objects (convert snake_case to camelCase)
        normalized_tags = options[:tags].map { |t| normalize_tag(t) }
        tags += normalized_tags
      end

      tags
    end

    def self.normalize_tag(tag)
      result = tag.dup
      # Convert external_docs to externalDocs
      if result.key?(:external_docs) && !result.key?(:externalDocs)
        result[:externalDocs] = result.delete(:external_docs)
      end
      result
    end

    def hide_documentation_path
      @@hide_documentation_path
    end

    def mount_path
      @@mount_path
    end

    def setup(options)
      options = DEFAULTS.merge(options)

      # options could be set on #add_swagger_documentation call,
      # for available options see #defaults
      target_class     = options[:target_class]
      guard            = options[:swagger_endpoint_guard]
      api_doc          = options[:api_documentation].dup
      specific_api_doc = options[:specific_api_documentation].dup

      class_variables_from(options)

      setup_formatter(options[:format])

      desc api_doc.delete(:desc), api_doc

      instance_eval(guard) unless guard.nil?

      get mount_path do
        header['Access-Control-Allow-Origin']   = '*'
        header['Access-Control-Request-Method'] = '*'

        GrapeSwagger::DocMethods
          .output_path_definitions(target_class.combined_namespace_routes, self, target_class, options)
      end

      desc specific_api_doc.delete(:desc), { params: specific_api_doc.delete(:params) || {}, **specific_api_doc }

      params do
        requires :name, type: String, desc: 'Resource name of mounted API'
        optional :locale, type: Symbol, desc: 'Locale of API documentation'
      end

      instance_eval(guard) unless guard.nil?

      get "#{mount_path}/:name" do
        I18n.locale = params[:locale] || I18n.default_locale

        combined_routes = target_class.combined_namespace_routes[params[:name]]
        error!({ error: 'named resource not exist' }, 400) if combined_routes.nil?

        GrapeSwagger::DocMethods
          .output_path_definitions({ params[:name] => combined_routes }, self, target_class, options)
      end
    end

    def class_variables_from(options)
      @@mount_path              = options[:mount_path]
      @@class_name              = options[:class_name] || options[:mount_path].delete('/')
      @@hide_documentation_path = options[:hide_documentation_path]
    end

    def setup_formatter(formatter)
      return unless formatter

      FORMATTER_METHOD.each { |method| send(method, formatter) }
    end
  end
end
