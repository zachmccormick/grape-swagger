# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

module GrapeSwaggerDemo
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true

    # Load Grape API files
    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths << Rails.root.join('app', 'api')

    # Eager load API classes
    config.eager_load_paths << Rails.root.join('app', 'api')
  end
end
