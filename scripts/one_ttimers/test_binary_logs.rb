require 'open3'
require 'pastel'
require 'active_support/core_ext/kernel/reporting'

lfw = LogFileWatcher.new
pastel = Pastel.new

(lfw.zipped_logs + lfw.binary_logs).each do |file|
  logfile = Logfile.new(file_path: file)
  puts pastel.red("\n\n\n\n\n************* #{logfile} **************")
  puts pastel.yellow(logfile.extract_contents)
end
