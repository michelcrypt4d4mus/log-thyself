require 'open3'
require 'pastel'
require 'active_support/core_ext/kernel/reporting'

lfw = LogFileWatcher.new
pastel = Pastel.new

lfw.binary_logs.each do |log_file|
  puts pastel.red("\n\n\n\n\n************* #{log_file} **************")
  contents = ''

  ShellCommandStreamer.new("syslog -f #{log_file}").stream! do |line|
    contents += line
  end

  puts contents
end


# Test zip logs
reload!
lf = Logfile.new(file_path: "/private/var/log/wifi.log.0.bz2")
lf.extract_contents
