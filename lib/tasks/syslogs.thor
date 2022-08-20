# TODO: break this into separate files, or, ideally, into subcommands
# subcommand documentation that is incredibly unhelpful: https://github.com/rails/thor/wiki/Subcommands
# "Collectthor" lol

require 'pastel'
load 'collector_command.thor'


module Collect
  class Syslog < CollectorCommand
    include StyledNotifications

    class_option :batch_size,
                  desc: "Rows to process between DB loads",
                  type: :numeric,
                  default: CsvDbWriter::BATCH_SIZE_DEFAULT

    desc 'stream', 'Collect logs from the syslog stream from now until you tell it to stop'
    option :level,
            desc: 'Level of logs to capture. debug is the most, info is the least.',
            enum: AppleJsonLogStreamParser::LOG_LEVELS,
            default: 'debug'
    def stream
      @shell_command = AppleJsonLogStreamParser::LOG_STREAM_SHELL_CMD
      @shell_command += " --level #{options[:level]}"
      launch_macos_log_parser(options)
    rescue StandardError, NoMethodError => e
      msg = "🚨 ERROR: #{e.class.to_s}: #{e.message}"
      say_and_log(msg, styles: [:red, :bold])
      say_and_log("(See logs for stack trace)")
      Rails.logger.error("#{msg}\n#{e.backtrace.join("\n")}")
    end

    desc 'last INTERVAL', "Capture from INTERVAL before now. Example INTERVALs: 5d (5 days), 2m (2 minutes), 30s (30 seconds)"
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
    desc 'from_file FILE', "Read logs from FILE. Will stream gzipped files automatically, can handle non JSON default 'log' output with --syslog option."
    option :syslog,
            desc: "FILE is the default format that streams from 'log show' or log stream when you don't use any --style option",
            type: :boolean,
            default: false
    def from_file(file)
      raise InvocationError.new("File #{file} does not exist!") unless File.exist?(file)
      cmd = File.extname(file) == '.gz' ? 'gunzip -c' : 'cat'
      @shell_command = "#{cmd} \"#{file}\""
      stream_parser_klass = options[:syslog] ? SyslogStreamParser : AppleJsonLogStreamParser
      StreamCoordinator.stream_to_db!(stream_parser_klass.new(@shell_command), MacOsSystemLog, options)
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
          streamer = AppleJsonLogStreamParser.new(@shell_command)
          StreamCoordinator.stream_to_db!(streamer, MacOsSystemLog, options)
        rescue Interrupt
          say "Stopping..."
        rescue StandardError, NoMethodError => e
          msg = "🚨 ERROR: #{e.class.to_s}: #{e.message}"
          say_and_log(msg, styles: [:red, :bold])
          say_and_log("(See logs for stack trace)")
          Rails.logger.error("#{msg}\n#{e.backtrace.join("\n")}")
        end
      end
    end
  end
end

