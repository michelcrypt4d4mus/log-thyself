# TODO: break this into separate files, or, ideally, into subcommands
# subcommand documentation that is incredibly unhelpful: https://github.com/rails/thor/wiki/Subcommands
# "Collectthor" lol

load 'collector_command.thor'


module Collect
  class Syslog < CollectorCommand
    desc 'stream', 'Collect logs from the syslog stream from now until you tell it to stop'
    option :level,
            desc: 'Level of logs to capture. debug is the most, info is the least.',
            enum: AppleJsonLogStreamParser::LOG_LEVELS,
            default: 'info'
    def stream
      @shell_command = AppleJsonLogStreamParser::LOG_STREAM_SHELL_CMD
      @shell_command += " --level #{options[:level]}"
      launch_macos_log_parser(options)
    end

    desc 'last INTERVAL', "Capture from INTERVAL before now using 'log show'. Example INTERVALs: 5d, 2m, 30s"
    def last(interval)
      @shell_command = "#{AppleJsonLogStreamParser::LOG_SHOW_SHELL_CMD} --last #{interval}"
      launch_macos_log_parser(options)
    end

    desc 'start DATETIME', "Collect logs since a given DATETIME in the past using 'log show'"
    def start(datetime)
      @shell_command = "#{AppleJsonLogStreamParser::LOG_SHOW_SHELL_CMD} --start \"#{datetime}\""
      launch_macos_log_parser(options)
    end

    # TODO: syslog format is also a way to reduce the log size...
    desc 'from_file FILE', 'Read logs from FILE'
    option :syslog,
            desc: "FILE is syslog format instead of JSON",
            type: :boolean,
            default: false
    def from_file(file)
      raise InvocationError.new("File #{file} does not exist!") unless File.exist?(file)
      cmd = File.extname(file) == '.gz' ? 'gunzip -c' : 'cat'
      @shell_command = "#{cmd} \"#{file}\""
      stream_parser_klass = options[:syslog] ? SyslogStreamParser : AppleJsonLogStreamParser
      StreamCoordinator.collect!(stream_parser_klass.new(@shell_command), options.merge(destination_klass: MacOsSystemLog))
    end

    desc 'custom ARGUMENTS', "ARGUMENTS will be passed to the 'log' command directly (with great 💪 comes great responsibility)"
    def custom(arguments)
      @shell_command = "log #{arguments}"
      launch_macos_log_parser(options)
    end

    no_commands do
      def launch_macos_log_parser(options)
        make_announcement

        begin
          StreamCoordinator.collect!(AppleJsonLogStreamParser.new(@shell_command), options.merge(destination_klass: MacOsSystemLog))
        rescue Interrupt
          say "Stopping..."
        end
      end
    end
  end
end
