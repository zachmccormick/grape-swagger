# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 File Parameters' do
  def app
    Class.new(Grape::API) do
      format :json

      desc 'Upload file'
      params do
        requires :file, type: File, desc: 'The file to upload'
        optional :name, type: String, desc: 'File name'
      end
      post '/upload' do
        { uploaded: true }
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  let(:post_operation) { subject['paths']['/upload']['post'] }

  describe 'BUG-005: formData is not valid in OpenAPI 3.x' do
    it 'does not have parameters with in: formData' do
      parameters = post_operation['parameters'] || []
      form_data_params = parameters.select { |p| p['in'] == 'formData' }
      expect(form_data_params).to be_empty,
                                  "Expected no formData parameters, but found: #{form_data_params}"
    end

    it 'uses requestBody for file uploads' do
      expect(post_operation).to have_key('requestBody')
    end
  end

  describe 'BUG-006: type file is not valid in OpenAPI 3.x' do
    it 'does not use type: file anywhere in the spec' do
      # Recursively search for type: file
      def find_file_types(obj, path = '')
        results = []
        case obj
        when Hash
          results << path if obj['type'] == 'file'
          obj.each do |key, value|
            results.concat(find_file_types(value, "#{path}/#{key}"))
          end
        when Array
          obj.each_with_index do |item, idx|
            results.concat(find_file_types(item, "#{path}[#{idx}]"))
          end
        end
        results
      end

      file_types = find_file_types(subject)
      expect(file_types).to be_empty,
                            "Found type: file at: #{file_types.join(', ')}"
    end

    it 'uses type: string with format: binary for file fields' do
      request_body = post_operation.dig('requestBody', 'content', 'multipart/form-data', 'schema')
      if request_body && request_body['properties']
        file_prop = request_body['properties']['file']
        if file_prop
          expect(file_prop['type']).to eq('string')
          expect(file_prop['format']).to eq('binary')
        end
      end
    end
  end
end
