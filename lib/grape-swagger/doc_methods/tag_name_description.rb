# frozen_string_literal: true

module GrapeSwagger
  module DocMethods
    class TagNameDescription
      class << self
        def build(paths)
          paths.values.each_with_object([]) do |path, memo|
            # Skip path items that are $ref references (OpenAPI 3.1.0)
            next if path.is_a?(Hash) && (path.key?('$ref') || path.key?(:$ref))

            first_operation = path.values.first
            next unless first_operation.is_a?(Hash)

            tags = first_operation[:tags]
            next if tags.nil?

            case tags
            when String
              memo << build_memo(tags)
            when Array
              path.values.first[:tags].each do |tag|
                memo << build_memo(tag)
              end
            end
          end.uniq
        end

        private

        def build_memo(tag)
          {
            name: tag,
            description: "Operations about #{tag.pluralize}"
          }
        end
      end
    end
  end
end
