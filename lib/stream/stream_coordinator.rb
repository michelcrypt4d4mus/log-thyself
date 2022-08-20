class StreamCoordinator
  def self.stream_to_db!(stream_parser, destination_klass, options)
    Rails.logger.level = "Logger::#{options[:app_log_level]}".constantize
    Rails.logger.info("#{self.name} options: #{options.pretty_inspect}")

    filters_klass = \
      case destination_klass.new
      when ObjectiveSeeEvent
        ObjectiveSeeEventFilterDefinitions
      when MacOsSystemLog
        FilterDefinitions
      else
        nil
      end

    filters_klass&.validate!
    filter_definitions = filters_klass ? filters_klass::FILTER_DEFINITIONS : []
    Rails.logger.info("Using #{filters_klass} to filter #{destination_klass} (#{filter_definitions.size} filters)")
    filter_set = FilterSet.new(filter_definitions, options) # unless ENV['RUNNING_FILTER_BENCHMARKS']
    disable_filters = !!options[:disable_filters]

    CsvDbWriter.open(destination_klass, options) do |db_writer|
      stream_parser.parse_stream! do |record|
        begin
          allowed = disable_filters ? true : filter_set.allow?(record)
          db_writer << record unless options[:read_only] || !allowed
        rescue NoMethodError => e
          # If we don't rescue NoMethodError thor will suppress it which is infuriating
          Rails.logger.error("#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        end
      end
    end
  end
end
