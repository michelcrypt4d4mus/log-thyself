load 'collector_command.thor'

module Objectivesee
  class ObjectiveSeeCOmmand < CollectorCommand
    class_option :command_line_flags,
                  desc: 'Command line flags to pass to executable command line (-pretty is not allowed)',
                  default: '-skipApple'
  end

  class FileMonitor < ObjectiveSeeCOmmand
    desc 'stream', "Collect file events from Objective-See's FileMonitor (requires sudo!)"
    option :executable_path,
            default: ProcessMonitorStreamParser::EXECUTABLE_PATH_DEFAULT,
            desc: 'Path to your FileMonitor executable'
    def stream
      raise InvocationError.new('-pretty is verboten') if options[:command_line_flags].include?('-pretty')
      StreamCoordinator.collect!(FileMonitorStreamParser.new(options), options.merge(destination_klass: FileEvent))
    end
  end

  class ProcessMonitor < ObjectiveSeeCOmmand
    desc 'stream', "Collect process events from Objective-See's ProcessMonitor (requires sudo!)"
    option :executable_path,
            default: ProcessMonitorStreamParser::EXECUTABLE_PATH_DEFAULT,
            desc: 'Path to your ProcessMonitor executable'
    def stream
      raise InvocationError.new('-pretty is verboten') if options[:command_line_flags].include?('-pretty')
      reader = ProcessMonitorStreamParser.new(options)
      StreamCoordinator.collect!(reader, options.merge(destination_klass: ProcessEvent))
    end
  end
end
