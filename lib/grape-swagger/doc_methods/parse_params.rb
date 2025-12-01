# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class ParseParams
      class << self
        def call(param, settings, path, route, definitions, consumes) # rubocop:disable Metrics/ParameterLists
          method = route.request_method
          additional_documentation = settings.fetch(:documentation, {})
          settings.merge!(additional_documentation)

          # Support $ref to component parameters (OpenAPI 3.1.0 feature)
          # Usage: documentation: { ref: '#/components/parameters/PageParam' }
          if settings[:ref]
            return { '$ref' => settings[:ref] }
          end

          data_type = DataType.call(settings)

          value_type = settings.merge(data_type: data_type, path: path, param_name: param, method: method)

          # required properties
          @parsed_param = {
            in: param_type(value_type, consumes),
            name: settings[:full_name] || param
          }

          # optional properties
          document_description(settings)
          document_type_and_format(settings, data_type)
          document_array_param(value_type, definitions) if value_type[:is_array]
          document_default_value(settings) unless value_type[:is_array]
          document_range_values(settings) unless value_type[:is_array]
          document_required(settings)
          document_length_limits(value_type)
          document_numeric_validation(value_type)
          document_additional_properties(definitions, settings) unless value_type[:is_array]
          document_add_extensions(settings)
          document_example(settings)
          document_deprecated(settings)
          document_read_write_only(settings)

          @parsed_param
        end

        private

        def document_description(settings)
          description = settings[:desc] || settings[:description]
          @parsed_param[:description] = description if description
        end

        def document_required(settings)
          @parsed_param[:required] = settings[:required] || false
          @parsed_param[:required] = true if @parsed_param[:in] == 'path'
        end

        def document_range_values(settings)
          values               = settings[:values] || nil
          enum_or_range_values = parse_enum_or_range_values(values)
          @parsed_param.merge!(enum_or_range_values) if enum_or_range_values
        end

        def document_default_value(settings)
          @parsed_param[:default] = settings[:default] if settings.key?(:default)
        end

        def document_type_and_format(settings, data_type)
          if DataType.primitive?(data_type)
            data = DataType.mapping(data_type)
            @parsed_param[:type], @parsed_param[:format] = data
          else
            @parsed_param[:type] = data_type
          end
          @parsed_param[:format] = settings[:format] if settings[:format].present?
        end

        def document_add_extensions(settings)
          GrapeSwagger::DocMethods::Extensions.add_extensions_to_root(settings, @parsed_param)
        end

        def document_array_param(value_type, definitions)
          if value_type[:documentation].present?
            doc_type = value_type[:documentation][:type]
            type = DataType.mapping(doc_type) if doc_type && !DataType.request_primitive?(doc_type)
            collection_format = value_type[:documentation][:collectionFormat]
          end

          array_items = parse_array_item(
            definitions,
            type,
            value_type
          )

          @parsed_param[:items] = array_items
          @parsed_param[:type] = 'array'
          @parsed_param[:collectionFormat] = collection_format if DataType.collections.include?(collection_format)
        end

        def parse_array_item(definitions, type, value_type)
          array_items = {}
          if definitions[value_type[:data_type]]
            array_items['$ref'] = "#/definitions/#{@parsed_param[:type]}"
          else
            array_items[:type] = type || @parsed_param[:type] == 'array' ? 'string' : @parsed_param[:type]
          end
          array_items[:format] = @parsed_param.delete(:format) if @parsed_param[:format]

          values = value_type[:values] || nil
          enum_or_range_values = parse_enum_or_range_values(values)
          array_items.merge!(enum_or_range_values) if enum_or_range_values

          array_items[:default] = value_type[:default] if value_type[:default].present?

          set_additional_properties, additional_properties = parse_additional_properties(definitions, value_type)
          array_items[:additionalProperties] = additional_properties if set_additional_properties

          if value_type.key?(:items)
            GrapeSwagger::DocMethods::Extensions.add_extensions_to_root(value_type[:items], array_items)
          end

          array_items
        end

        def document_additional_properties(definitions, settings)
          set_additional_properties, additional_properties = parse_additional_properties(definitions, settings)
          @parsed_param[:additionalProperties] = additional_properties if set_additional_properties
        end

        def parse_additional_properties(definitions, settings)
          return false unless settings.key?(:additionalProperties) || settings.key?(:additional_properties)

          value =
            if settings.key?(:additionalProperties)
              GrapeSwagger::Errors::SwaggerSpecDeprecated.tell!(:additionalProperties)
              settings[:additionalProperties]
            else
              settings[:additional_properties]
            end

          parsed_value =
            if definitions[value.to_s]
              { '$ref': "#/definitions/#{value}" }
            elsif value.is_a?(Class)
              { type: DataType.call(value) }
            else
              value
            end

          [true, parsed_value]
        end

        def document_example(settings)
          return unless settings.key?(:example)

          key = @parsed_param[:in] == 'body' ? :example : :'x-example'
          @parsed_param[key] = settings[:example]
        end

        def document_deprecated(settings)
          @parsed_param[:deprecated] = settings[:deprecated] if settings.key?(:deprecated)
        end

        def document_read_write_only(settings)
          @parsed_param[:readOnly] = settings[:read_only] if settings.key?(:read_only)
          @parsed_param[:writeOnly] = settings[:write_only] if settings.key?(:write_only)
        end

        def param_type(value_type, consumes)
          param_type = value_type[:param_type] || value_type[:in]
          if !value_type[:is_array] && value_type[:path].include?("{#{value_type[:param_name]}}")
            'path'
          elsif param_type
            param_type
          elsif %w[POST PUT PATCH].include?(value_type[:method])
            if consumes.include?('application/x-www-form-urlencoded') || consumes.include?('multipart/form-data')
              'formData'
            else
              'body'
            end
          elsif value_type[:is_array] && !DataType.query_array_primitive?(value_type[:data_type])
            'formData'
          else
            'query'
          end
        end

        def document_length_limits(value_type)
          if value_type[:is_array]
            @parsed_param[:minItems] = value_type[:min_length] if value_type.key?(:min_length)
            @parsed_param[:maxItems] = value_type[:max_length] if value_type.key?(:max_length)
            @parsed_param[:uniqueItems] = value_type[:unique_items] if value_type.key?(:unique_items)
          else
            @parsed_param[:minLength] = value_type[:min_length] if value_type.key?(:min_length)
            @parsed_param[:maxLength] = value_type[:max_length] if value_type.key?(:max_length)
          end
        end

        def document_numeric_validation(value_type)
          @parsed_param[:exclusiveMinimum] = value_type[:exclusive_minimum] if value_type.key?(:exclusive_minimum)
          @parsed_param[:exclusiveMaximum] = value_type[:exclusive_maximum] if value_type.key?(:exclusive_maximum)
          @parsed_param[:multipleOf] = value_type[:multiple_of] if value_type.key?(:multiple_of)
        end

        def parse_enum_or_range_values(values)
          case values
          when Proc
            parse_enum_or_range_values(values.call) if values.parameters.empty?
          when Range
            parse_range_values(values) if values.first.is_a?(Numeric)
          when Array
            { enum: values }
          else
            { enum: [values] } if values
          end
        end

        def parse_range_values(values)
          result = { minimum: values.begin }

          if values.exclude_end?
            # Exclusive end range (0...1.0) -> exclusiveMaximum
            result[:exclusiveMaximum] = values.end
          else
            # Inclusive range (0..1.0) -> maximum
            result[:maximum] = values.end
          end

          result.compact
        end
      end
    end
  end
end
