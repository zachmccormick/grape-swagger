# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
  config.cache_classes = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = :none

  # Disable caching
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
end
