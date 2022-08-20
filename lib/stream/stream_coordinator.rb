class StreamCoordinator
  def self.stream_to_db!(stream_parser, destination_klass, options)
    Rails.logger.level = "Logger::#{options[:app_log_level]}".constantize
    Rails.logger.info("#{self.name} options: #{options.pretty_inspect}")

    filters_klass = \
      case destination_klass
      when ObjectiveSeeEvent
        ObjectiveSeeEventFilterDefinitions
      when MacOsSystemLog
        FilterDefinitions
      else
        nil
      end

    filter_definitions = filters_klass ? filters_klass::FILTER_DEFINITIONS : []
    filter_set = FilterSet.new(filter_definitions, options) # unless ENV['RUNNING_FILTER_BENCHMARKS']
    disable_filters = !!options[:disable_filters]
    rows_read = 0

    CsvDbWriter.open(destination_klass, options) do |db_writer|
      stream_parser.parse_stream! do |record|
        rows_read += 1
        allowed = disable_filters ? true : LogEventFilter.allow?(record)
        db_writer << record unless options[:read_only] || !allowed
      end
    end

    rows_read
  end
end
