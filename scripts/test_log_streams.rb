log_watcher = LogFileWatcher.new

log_watcher.read_log_streams do |filename, line, line_number|
  puts "#{filename} (line #{line_number}): #{line}"
end
