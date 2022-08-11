class StreamCoordinator
  ENABLE_FILTERS = false

  def self.collect!(shell_command, options)
    Rails.logger.level = "Logger::#{options[:app_log_level]}".constantize
    Rails.logger.info("#{self.name} options: #{options}")

    # TODO: Syslog/JSON stream parser should have same interfaces...
    stream_parser = options[:syslog] ? SyslogStreamParser.new : JsonStreamParser
    db_writer = CsvDbWriter.new(MacOsSystemLog, options)
    LogEventFilter.build_filters!

    begin
      stream_parser.parse_shell_command_stream(shell_command) do |record|
        allowed = ENABLE_FILTERS ? LogEventFilter.allow?(record) : true
        db_writer.write(record) unless options[:read_only] || !allowed
      end
    ensure
      db_writer.close unless options[:read_only]
    end
  end
end
