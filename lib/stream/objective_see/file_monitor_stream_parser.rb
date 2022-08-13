class FileMonitorStreamParser < ObjectiveSeeJsonStreamParser
  EXECUTABLE_PATH_DEFAULT = '/Applications/FileMonitor.app/Contents/MacOS/FileMonitor'
  EXECUTABLE_VERSION = '1.3.0'
  STATS_PRINTOUT_INTERVAL_DEFAULT = 1000

  def initialize(options = {})
    executable_path = options[:executable_path] || EXECUTABLE_PATH_DEFAULT
    super(executable_path, options)
  end
end
