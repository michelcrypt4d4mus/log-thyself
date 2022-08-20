require_relative "boot"
require "rails/all"

# Require the gems listed in Gemfile
Bundler.require(*Rails.groups)


module MacosLogCollector
  class Application < Rails::Application
    config.load_defaults 7.0
    config.active_record.schema_format = :sql

    Dir[Rails.root.join('lib', '**/')].each { |dir| config.eager_load_paths << dir.to_s }
    config.eager_load_paths << Rails.root.join('config', 'filter_definitions').to_s
  end
end
