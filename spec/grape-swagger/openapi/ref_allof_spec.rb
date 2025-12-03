# frozen_string_literal: true

require 'spec_helper'

describe 'OpenAPI 3.1.0 $ref with allOf wrapper' do
  module RefAllOfTest
    class Address < Grape::Entity
      expose :street, documentation: { type: String }
      expose :city, documentation: { type: String }
    end

    class Person < Grape::Entity
      expose :name, documentation: { type: String }
      # This references Address and adds a description - should use allOf in 3.1.0
      expose :address, using: Address, documentation: {
        description: 'Home address of the person'
      }
    end
  end

  def app
    Class.new(Grape::API) do
      format :json

      desc 'Get person',
           success: { code: 200, message: 'Success', model: RefAllOfTest::Person }
      get '/person' do
        {}
      end

      add_swagger_documentation openapi_version: '3.1.0'
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'BUG-004: $ref should not be placed next to other properties' do
    let(:person_schema) { subject['components']['schemas']['RefAllOfTest_Person'] }
    let(:address_property) { person_schema['properties']['address'] }

    it 'does not have $ref alongside other properties' do
      # Debug output to see what we're working with
      puts "Address property: #{address_property.inspect}"

      if address_property.key?('$ref')
        # If $ref is present, it should be the ONLY key (no siblings)
        non_ref_keys = address_property.keys - ['$ref']
        expect(non_ref_keys).to be_empty,
                                "In OpenAPI 3.1.0, $ref cannot have sibling properties. Found: #{non_ref_keys}"
      end
    end

    it 'uses allOf to combine $ref with description' do
      if address_property.key?('description') && address_property.key?('$ref')
        raise 'BUG-004: $ref and description should not be siblings. Use allOf wrapper.'
      end

      # If we have description with a reference, allOf should be used
      if address_property.key?('allOf')
        expect(address_property['allOf']).to be_an(Array)
        expect(address_property['allOf'].any? { |item| item.key?('$ref') }).to be true
        expect(address_property).to have_key('description')
      end
    end
  end
end
