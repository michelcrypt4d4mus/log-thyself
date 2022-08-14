class StreamCoordinator
  def self.collect!(stream_parser, options)
    raise 'No :destination_klass provided' unless options[:destination_klass]
    Rails.logger.level = "Logger::#{options[:app_log_level]}".constantize
    Rails.logger.info("#{self.name} options: #{options}")

    LogEventFilter.build_filters!
    disable_filters = !!options[:disable_filters]
    Rails.logger.warn("Filters #{disable_filters ? 'disabled' : 'enabled'}")

    CsvDbWriter.open(options[:destination_klass], options) do |db_writer|
      stream_parser.parse_stream! do |record|
        allowed = disable_filters ? true : LogEventFilter.allow?(record)
        db_writer << record unless options[:read_only] || !allowed
      end
    end
  end
end
