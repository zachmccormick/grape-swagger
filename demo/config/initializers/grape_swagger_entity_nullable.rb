# frozen_string_literal: true

# Monkey-patch grape-swagger-entity to support nullable documentation option
# This should eventually be upstreamed to the grape-swagger-entity gem

module GrapeSwagger
  module Entity
    class AttributeParser
      # Override add_attribute_documentation to include nullable support
      alias original_add_attribute_documentation add_attribute_documentation

      def add_attribute_documentation(param, documentation)
        original_add_attribute_documentation(param, documentation)

        # Add nullable support for OpenAPI 3.1.0
        param[:nullable] = true if documentation[:nullable]
      end
    end
  end
end
