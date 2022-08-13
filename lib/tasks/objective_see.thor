load 'collector_command.thor'

module Objectivesee
  class ObjectiveSeeCommand < CollectorCommand
    class_option :command_line_flags,
                  desc: 'Command line flags to pass to executable command line (-pretty is not allowed)',
                  default: '-skipApple'

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
            default: ProcessMonitorStreamParser::EXECUTABLE_PATH_DEFAULT,
            desc: 'Path to your FileMonitor executable'
    def stream
      validate_and_announce(options)
      StreamCoordinator.collect!(FileMonitorStreamParser.new(options), options.merge(destination_klass: FileEvent))
    end
  end

  class ProcessMonitor < ObjectiveSeeCommand
    desc 'stream', "Collect process events from ProcessMonitor (requires sudo!)"
    option :executable_path,
            default: ProcessMonitorStreamParser::EXECUTABLE_PATH_DEFAULT,
            desc: 'Path to your ProcessMonitor executable'
    def stream
      validate_and_announce(options)
      StreamCoordinator.collect!(ProcessMonitorStreamParser.new(options), options.merge(destination_klass: ProcessEvent))
    end
  end
end
