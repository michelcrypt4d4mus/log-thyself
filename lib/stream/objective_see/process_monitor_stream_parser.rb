class ProcessMonitorStreamParser < ObjectiveSeeJsonStreamParser
  EXECUTABLE_PATH_DEFAULT = '/Applications/ProcessMonitor.app/Contents/MacOS/ProcessMonitor'
  EXECUTABLE_VERSION = '1.5.0'
  STATS_PRINTOUT_INTERVAL_DEFAULT = 50

  def initialize(options = {})
    executable_path = options[:executable_path] || EXECUTABLE_PATH_DEFAULT
    super(executable_path, options)
  end
end
