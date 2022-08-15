class StreamCoordinator
  def self.collect!(stream_parser, options)
    raise 'No :destination_klass provided' unless options[:destination_klass]
    Rails.logger.level = "Logger::#{options[:app_log_level]}".constantize
    Rails.logger.info("#{self.name} options: #{options}")

    LogEventFilter.build_filters! unless ENV['RUNNING_FILTER_BENCHMARKS']
    disable_filters = !!options[:disable_filters]
    Rails.logger.warn("Filters #{disable_filters ? 'disabled' : 'enabled'}")
    rows_read = 0

    CsvDbWriter.open(options[:destination_klass], options) do |db_writer|
      stream_parser.parse_stream! do |record|

        rows_read += 1
        allowed = disable_filters ? true : LogEventFilter.allow?(record)
        db_writer << record unless options[:read_only] || !allowed
      end
    end

    rows_read
  end
end
