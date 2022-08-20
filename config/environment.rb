# Load the Rails application.
require_relative 'application'

Rails.application.configure do
  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Show full error reports.
  config.consider_all_requests_local = true

  # There's no web interface so we don't care about encrypting cookies etc.
  config.require_master_key = false
  config.read_encrypted_secrets = false

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    logger.level = Logger::DEBUG
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end

# Initialize the Rails application.
Rails.application.initialize!
