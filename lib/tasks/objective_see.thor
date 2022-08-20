load 'collector_command.thor'


module Objectivesee
  class ObjectiveSeeCommand < CollectorCommand
    class_option :command_line_flags,
                  desc: 'Flags to pass through to executable command line (-pretty is not allowed)',
                  default: '-skipApple'

    class_option :read_from_file,
                  type: :string,
                  desc: 'Read from the specified file instead of streaming from the application'

    no_commands do
      def validate_and_announce(options)
        raise InvocationError.new('-pretty is verboten') if options[:command_line_flags].include?('-pretty')
        make_announcement
      end
    end
  end


  class FileMonitor < ObjectiveSeeCommand
    desc 'stream', "Collect file events from FileMonitor (requires sudo!)"
    option :executable_path,
            default: FileMonitorStreamParser::EXECUTABLE_PATH_DEFAULT,
            desc: 'Path to your FileMonitor executable'
    option :batch_size,
            desc: "Rows between DB loads. With -skipApple it can take a while to fill a large buffer (far longer than the main system logs)",
            default: FileEvent.preferred_batch_size,
            type: :numeric
    def stream
      validate_and_announce(options)
      StreamCoordinator.stream_to_db!(FileMonitorStreamParser.new(options), FileEvent, options)
    end
  end

  class ProcessMonitor < ObjectiveSeeCommand
    desc 'stream', "Collect process events from ProcessMonitor (requires sudo!)"
    option :executable_path,
            default: ProcessMonitorStreamParser::EXECUTABLE_PATH_DEFAULT,
            desc: 'Path to your ProcessMonitor executable'
    option :batch_size,
            desc: "Rows between DB loads. With -skipApple it can take a while to fill a large buffer (far longer than the main system logs)",
            default: ProcessEvent.preferred_batch_size,
            type: :numeric
    def stream
      validate_and_announce(options)
      StreamCoordinator.stream_to_db!(ProcessMonitorStreamParser.new(options), ProcessEvent, options)
    end
  end
end
