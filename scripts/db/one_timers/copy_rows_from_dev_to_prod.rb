require 'fileutils'

ROW_COUNT = 6_077_551
BATCH_SIZE = 500_000

# Need to move psqlrc temporarily
psqlrc = File.join(Dir.home, '.psqlrc')
#FileUtils.mv(psqlrc, psqlrc + '.bak', verbose: true)

i = 0

while i < ROW_COUNT
  select_statement = "SELECT * FROM macos_system_logs ORDER BY id LIMIT #{BATCH_SIZE} OFFSET #{i}"
  cmd = "psql macos_log_collector_development -c'COPY (#{select_statement}) TO STDOUT' 2>/dev/null | psql macos_log_collector -c'copy macos_system_logs FROM STDIN'"
  puts cmd
  system(cmd)
  i += BATCH_SIZE
end

FileUtils.mv(psqlrc + '.bak', psqlrc, verbose: true)
