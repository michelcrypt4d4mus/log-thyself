# TODO: break this into separate files, or, ideally, into subcommands
# subcommand documentation that is incredibly unhelpful: https://github.com/rails/thor/wiki/Subcommands
# "Collectthor" lol

module Collect
  class CollectorCommandBase < Thor
    class_option :app_log_level,
      desc: "This application's logging verbosity",
      default: 'INFO',
      enum: Logger::Severity.constants.map(&:to_s).sort_by { |l| "Logger::#{l}".constantize },
      banner: 'LEVEL'

    class_option :batch_size,
      default: CsvDbWriter::BATCH_SIZE_DEFAULT,
      type: :numeric,
      desc: "Rows to process between DB loads"

    class_option :avoid_dupes,
      desc: 'Attempt to avoid dupes by going a lot slower',
      type: :boolean,
      default: false

    class_option :read_only,
      desc: "Just read and process the streams, don't save to the database.",
      type: :boolean,
      default: false

    # Thor complains if this is not defined and there's an error
    def self.exit_on_failure?; end
  end


  class FileMonitor < CollectorCommandBase
    desc 'stream', "Collect file events from Objective-See's File Monitor tool (requires sudo!)"
    option :file_monitor_path,
            default: FileMonitorStreamParser::FILE_MONITOR_EXECUTABLE_DEFAULT_PATH,
            desc: 'Path to your FileMonitor executable'
    option :file_monitor_flags,
            desc: 'Flags to pass to FileMonitor command line (-pretty is not allowed)',
            default: '-skipApple'
    def stream
      raise InvocationError.new('-pretty is verboten') if options[:file_monitor_flags].include?('-pretty')
      writer = CsvDbWriter.new(FileEvent, options)

      begin
        FileMonitorStreamParser.new.parse_shell_command_stream do |file_event|
          writer.write(file_event)
        end
      ensure
        db_writer.close
      end
    end
  end


  class Syslog < CollectorCommandBase
    desc 'stream', 'Collect logs from the syslog stream from now until you tell it to stop'
    option :level,
            desc: 'Level of logs to capture. debug is the most, info is the least.',
            enum: JsonStreamParser::LOG_LEVELS,
            default: 'info'
    def stream
      @shell_command = JsonStreamParser::LOG_STREAM_SHELL_CMD
      @shell_command += " --level #{options[:level]}"
      launch_macos_log_parser(options)
    end

    desc 'last INTERVAL', "Capture from INTERVAL before now using 'log show'. Example INTERVALs: 5d, 2m, 30s"
    def last(interval)
      @shell_command = "#{JsonStreamParser::LOG_SHOW} --last #{interval}"
      launch_macos_log_parser(options)
    end

    desc 'start DATETIME', "Collect logs since a given DATETIME in the past using 'log show'"
    def start(datetime)
      @shell_command = "#{JsonStreamParser::LOG_SHOW} --start \"#{datetime}\""
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
      launch_macos_log_parser(options)
    end

    desc 'custom ARGUMENTS', "ARGUMENTS will be passed on to the 'log' command directly. with great power comes great responsibility 💪"
    def custom(arguments)
      @shell_command = "log #{arguments}"
      launch_macos_log_parser(options)
    end

    no_commands do
      def launch_macos_log_parser(options)
        say "\n🌀 Summoning log stream vortex...🌀\n", :cyan
        say "        (CTRL-C to stop)"
        StreamCoordinator.collect!(@shell_command, options)
      end
    end
  end
end
