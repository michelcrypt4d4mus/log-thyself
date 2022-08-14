class StreamCoordinator
  ENABLE_FILTERS = false

  def self.collect!(stream_parser, options)
    raise 'No :destination_klass provided' unless options[:destination_klass]
    Rails.logger.level = "Logger::#{options[:app_log_level]}".constantize
    Rails.logger.info("#{self.name} options: #{options}")
    LogEventFilter.build_filters!

    CsvDbWriter.open(options[:destination_klass], options) do |db_writer|
      stream_parser.parse_stream! do |record|
        allowed = ENABLE_FILTERS ? LogEventFilter.allow?(record) : true
        db_writer << record unless options[:read_only] || !allowed
      end
    end
  end
end
