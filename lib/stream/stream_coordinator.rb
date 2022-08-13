class StreamCoordinator
  ENABLE_FILTERS = false

  def self.collect!(stream_parser, options)
    Rails.logger.level = "Logger::#{options[:app_log_level]}".constantize
    Rails.logger.info("#{self.name} options: #{options}")
    LogEventFilter.build_filters!

    raise 'No :destination_klass provided' unless options[:destination_klass]
    db_writer = CsvDbWriter.new(options[:destination_klass], options)

    begin
      stream_parser.parse_stream! do |record|
        allowed = ENABLE_FILTERS ? LogEventFilter.allow?(record) : true
        db_writer.write(record) unless options[:read_only] || !allowed
      end
    ensure
      db_writer.close unless options[:read_only]
    end
  end
end
