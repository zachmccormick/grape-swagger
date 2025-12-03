# frozen_string_literal: true

module GrapeSwagger
  module OpenAPI
    # Transforms Swagger 2.0 style discriminators to OpenAPI 3.1.0 format
    # Swagger 2.0: "discriminator": "pet_type"
    # OpenAPI 3.1.0: "discriminator": { "propertyName": "pet_type", "mapping": { "dog": "#/..." } }
    class DiscriminatorTransformer
      class << self
        # Transform all discriminators in the schemas
        #
        # @param schemas [Hash] The components/schemas hash
        # @param version [GrapeSwagger::OpenAPI::Version] The OpenAPI version
        # @return [Hash] Schemas with transformed discriminators
        def transform(schemas, version)
          return schemas if version.swagger_2_0?
          return schemas unless schemas.is_a?(Hash)

          # Build parent-child relationships
          relationships = build_relationships(schemas)

          # Transform parent schema discriminators
          schemas.each do |name, schema|
            transform_schema(name, schema, relationships, version)
          end

          # Fix child schema discriminator property enum values
          fix_child_discriminator_enums(schemas, relationships)

          schemas
        end

        private

        # Build a map of parent schemas to their child schemas
        #
        # @param schemas [Hash] All schemas
        # @return [Hash] Map of parent_name => [{ child_name:, discriminator_value: }]
        def build_relationships(schemas)
          relationships = Hash.new { |h, k| h[k] = [] }

          schemas.each do |name, schema|
            next unless schema.is_a?(Hash)

            # Check if this schema uses allOf to reference a parent
            all_of = schema[:allOf] || schema['allOf']
            next unless all_of.is_a?(Array)

            # Find the parent reference
            parent_ref = find_parent_ref(all_of)
            next unless parent_ref

            parent_name = extract_schema_name(parent_ref)
            next unless parent_name

            # Find the discriminator value in the extension schema
            discriminator_value = find_discriminator_value(all_of, name, schemas[parent_name])

            relationships[parent_name] << {
              child_name: name,
              discriminator_value: discriminator_value
            }
          end

          relationships
        end

        # Find the $ref to the parent in an allOf array
        def find_parent_ref(all_of)
          all_of.each do |schema|
            ref = schema['$ref'] || schema[:$ref]
            return ref if ref
          end
          nil
        end

        # Extract schema name from a $ref
        def extract_schema_name(ref)
          return nil unless ref.is_a?(String)

          # Handle both #/definitions/Name and #/components/schemas/Name
          return unless ref.include?('#/')

          ref.split('/').last
        end

        # Find the discriminator value in the child schema's allOf
        def find_discriminator_value(all_of, child_name, parent_schema)
          return nil unless parent_schema.is_a?(Hash)

          # Get the discriminator property name from the parent
          disc_prop = parent_schema[:discriminator] || parent_schema['discriminator']
          # Handle both String and Symbol discriminator values
          return nil unless disc_prop.is_a?(String) || disc_prop.is_a?(Symbol)

          disc_prop = disc_prop.to_s

          # Look for the discriminator property override in the child's extension schema
          all_of.each do |schema|
            next if schema['$ref'] || schema[:$ref]

            props = schema[:properties] || schema['properties']
            next unless props.is_a?(Hash)

            disc_schema = props[disc_prop.to_sym] || props[disc_prop]
            next unless disc_schema.is_a?(Hash)

            enum = disc_schema[:enum] || disc_schema['enum']
            next unless enum.is_a?(Array) && enum.length == 1

            enum_value = enum.first
            # If the enum value looks like an entity name (e.g., V1_Entities_Dog),
            # extract the discriminator value from it instead
            return enum_value unless entity_name_pattern?(enum_value)
          end

          # Default to extracting from the schema name
          # e.g., V1_Entities_Dog -> dog
          derive_discriminator_value(child_name)
        end

        # Check if a value looks like an entity name pattern (e.g., V1_Entities_Dog)
        def entity_name_pattern?(value)
          return false unless value.is_a?(String)

          # Entity names typically have underscores and multiple parts
          # with capitalized segments like V1_Entities_Dog
          value.include?('_') && value.match?(/^[A-Z]/)
        end

        # Derive a discriminator value from the schema name
        # e.g., V1_Entities_Dog -> dog, V1_Entities_CreditCard -> credit_card
        def derive_discriminator_value(schema_name)
          return nil unless schema_name.is_a?(String)

          # Extract the last part of the name (after V1_Entities_ prefix or similar)
          parts = schema_name.split('_')

          # Get everything after common prefixes like V1_Entities_
          # Find the last meaningful part (not a version or 'Entities')
          meaningful_parts = parts.grep_v(/^(V\d+|Entities)$/i)

          return parts.last&.downcase if meaningful_parts.empty?

          # Convert CamelCase to snake_case if needed
          # e.g., CreditCard -> credit_card
          result = meaningful_parts.join
          result.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
        end

        # Transform a single schema's discriminator
        def transform_schema(name, schema, relationships, _version)
          return unless schema.is_a?(Hash)

          # Check if this schema has a string/symbol discriminator (Swagger 2.0 style)
          disc_key = find_key(schema, 'discriminator')
          return unless disc_key

          disc_value = schema[disc_key]
          # Handle both String and Symbol discriminator values
          return unless disc_value.is_a?(String) || disc_value.is_a?(Symbol)

          disc_value = disc_value.to_s

          # Build the mapping from children
          children = relationships[name]
          mapping = {}

          children.each do |child|
            disc_val = child[:discriminator_value]
            next unless disc_val

            mapping[disc_val] = "#/components/schemas/#{child[:child_name]}"
          end

          # Replace the string discriminator with the object format
          schema[disc_key] = {
            propertyName: disc_value
          }

          schema[disc_key][:mapping] = mapping if mapping.any?
        end

        # Fix child schemas' discriminator property enum values
        # e.g., change { pet_type: { enum: ["V1_Entities_Dog"] } }
        #       to     { pet_type: { enum: ["dog"] } }
        def fix_child_discriminator_enums(schemas, relationships)
          relationships.each do |parent_name, children|
            parent_schema = schemas[parent_name]
            next unless parent_schema.is_a?(Hash)

            # Get the discriminator object (should already be transformed)
            disc = parent_schema[:discriminator] || parent_schema['discriminator']
            next unless disc.is_a?(Hash)

            disc_prop = disc[:propertyName] || disc['propertyName']
            next unless disc_prop

            # Fix each child's discriminator enum
            children.each do |child|
              child_schema = schemas[child[:child_name]]
              next unless child_schema.is_a?(Hash)

              fix_child_enum(child_schema, disc_prop, child[:discriminator_value])
            end
          end
        end

        # Fix a single child schema's discriminator enum
        def fix_child_enum(child_schema, disc_prop, correct_value)
          all_of = child_schema[:allOf] || child_schema['allOf']
          return unless all_of.is_a?(Array)

          all_of.each do |schema|
            next if schema['$ref'] || schema[:$ref]

            props = schema[:properties] || schema['properties']
            next unless props.is_a?(Hash)

            disc_schema = props[disc_prop.to_sym] || props[disc_prop]
            next unless disc_schema.is_a?(Hash)

            # Update the enum with the correct discriminator value
            enum_key = disc_schema.key?(:enum) ? :enum : 'enum'
            disc_schema[enum_key] = [correct_value] if disc_schema[enum_key]
          end
        end

        # Find key supporting both string and symbol
        def find_key(hash, string_key)
          return string_key if hash.key?(string_key)

          symbol_key = string_key.to_sym
          symbol_key if hash.key?(symbol_key)
        end
      end
    end
  end
end
