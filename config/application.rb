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

    Dir[File.join(Rails.root, 'lib', '**/')].each do |dir|
      config.eager_load_paths << dir   # without the to_s() irb crashes :(
    end

    config.eager_load_paths << File.join(Rails.root, 'config', 'filter_definitions')
  end
end
