class ProcessMonitorStreamParser < ObjectiveSeeJsonStreamParser
  STATS_PRINTOUT_INTERVAL_DEFAULT = 10
  EXECUTABLE_PATH_DEFAULT = '/Applications/ProcessMonitor.app/Contents/MacOS/ProcessMonitor'

  def initialize(options = {})
    executable_path = options[:executable_path] || EXECUTABLE_PATH_DEFAULT
    super(executable_path, options)
  end
end
