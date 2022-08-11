require_relative "boot"
require "rails/all"

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)

module MacosLogCollector
  class Application < Rails::Application
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties can be overridden in specific
    # environments using the files in config/environments, which are processed later.

    # config.time_zone = "Central Time (US & Canada)"
    config.eager_load_paths << Rails.root.join("lib").to_s  # without the to_s() irb crashes :(
  end
end
