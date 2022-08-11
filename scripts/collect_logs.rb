# Main entry point to the application.

require 'optparse'

require File.join(Rails.root, 'lib', 'syslog_stream_parser')

JSON_STYLE = '--style json'
LOG_STREAM_SHELL_CMD = "log stream --source #{JSON_STYLE}"
LOG_SHOW = "log show --color none #{JSON_STYLE}"
LOG_LEVELS = [:default, :info, :debug]
APP_LOG_LEVELS = [:ERROR, :WARN, :INFO, :DEBUG]
STREAM_FLAG = '--stream'

DEFAULT_OPTIONS = {
  app_log_level: 'INFO',
  batch_size: CsvDbWriter::BATCH_SIZE_DEFAULT,
  log_level: 'debug'
}

DEFAULTS_BANNER = DEFAULT_OPTIONS.inject("\nDEFAULTS:") do |msg, (k, v)|
  "#{msg}\n#{sprintf('%24s: %s', '--' + k.to_s.gsub('_', '-'), v)}"
end

BANNER = """
You MUST specify one of the input options. Only --stream will continue processing logs into the future; the others will exit when the source is exhausted.

You may also care about the --log-level option because ith default settings the app captures A LOT of data - many gigabytes per hour. 'default' is the least data, 'debug' the most. (Don't be confused by the fact that 'default' is a log level string that has nothing to do with default options for this application.)

"""


class LogLoaderOptionParser
  def self.parse_command_line_arguments
    options = DEFAULT_OPTIONS.dup
    @shell_command = nil

    OptionParser.new do |opts|
      opts.banner = BANNER

      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        puts DEFAULTS_BANNER
        exit
      end

      opts.on('-s', STREAM_FLAG, "Continually capture the stream of events starting now.") do |v|
        @shell_command = LOG_STREAM_SHELL_CMD
      end

      opts.on('-l', '--last INTERVAL', /\d+[dmhs]/, "Capture from INTERVAL before now to now. Examples: '--last 2m' or '--last 3h'") do |log_show_last_arg|
        check_shell_command!
        @shell_command = "#{LOG_SHOW} --last #{log_show_last_arg}"
      end

      opts.on('-f', '--file FILE', 'Read from FILE.') do |file|
        check_shell_command!
        raise OptionParser::InvalidArgument.new("File #{file} does not exist!") unless File.exist?(file)
        cmd = File.extname(file) == '.gz' ? 'gunzip -c' : 'cat'
        @shell_command = "#{cmd} \"#{file}\""
      end

      opts.on('--start START_TIME', "Capture from START_TIME to now. Example: --start \"2022-05-01 06:03:44\"") do |log_show_start_arg|
        check_shell_command!
        @shell_command = "#{LOG_SHOW} --start \"#{log_show_start_arg}\""
      end

      opts.on('--log-level LEVEL', LOG_LEVELS, "Options: [#{LOG_LEVELS.join(', ')}] Log capture LEVEL, only with --stream") do |log_level|
        raise OptionParser::InvalidArgument('--log-level only works with --stream') if @shell_command !~ /log stream/
        @shell_command += " --level #{log_level}"
      end

      opts.on('--app-log-level LEVEL', APP_LOG_LEVELS, "Options: [#{APP_LOG_LEVELS.join(', ')}] Log level of the app, NOT the captured data") do |app_log_level|
        options[:app_log_level] = app_log_level
      end

      opts.on('--syslog-format', 'Use syslog format. Primarily to be used with --file to load old non JSON logs') do
        options[:syslog_format] = true
      end

      opts.on('--batch-size LINES', Integer, "Rows to process between DB loads") do |batch_size|
        options[:batch_size] = batch_size
      end

      opts.on('-c', '--custom-shell-command COMMAND', "Be your own master: write any log command") do |custom_shell_command|
        @shell_command = custom_shell_command
        @shell_command += ' --style json'
      end

      opts.on('--avoid-dupes', 'Attempt to avoid dupes by going a lot slower') do |d|
        options[:avoid_dupes] = true
      end
    end.parse!

    if @shell_command.nil?
      raise OptionParser::ParseError.new("You must specify a log source.")
    end

    options.merge(shell_command: @shell_command)
  end

  private

  def self.check_shell_command!
    raise OptionParser::ParseError.new('Can only read one source') if @shell_command
  end
end

begin
  options = LogLoaderOptionParser.parse_command_line_arguments
rescue OptionParser::ParseError => e
  puts "*** #{e.message} *** [#{e.class}]\n\n"
  puts "Run with --help for usage message."
  exit
end

Rails.logger.level = "Logger::#{options[:app_log_level]}".constantize
Rails.logger.info("Runtime Options #{options.pretty_inspect}")
shell_command = options[:shell_command]
db_writer = CsvDbWriter.new(MacOsSystemLog, options)

# TODO: Syslog/JSON stream parser should have same interfaces...
streamer = options[:syslog_format] ? SyslogStreamParser..new : JsonStreamParser
puts "Summoning log stream vortex... (CTRL-C to stop)" if shell_command.include?(STREAM_FLAG)

begin
  streamer.parse_shell_command_stream(shell_command) do |record|
    db_writer.write(record)
  end
ensure
  db_writer.close
end
