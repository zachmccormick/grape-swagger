# frozen_string_literal: true

# Require Grape and related gems
require 'grape'
require 'grape-entity'
require 'grape-swagger'
require 'grape-swagger-entity'

# Require API files in correct order
api_path = Rails.root.join('app', 'api')

# Load entities first
Dir[api_path.join('v1', 'entities', '*.rb')].each { |f| require f }

# Load API endpoints
Dir[api_path.join('v1', '*_api.rb')].each { |f| require f }

# Load root API last
require api_path.join('api', 'root.rb')
