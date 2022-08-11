# Watches logs from the old file system
require 'open3'

# TODO we could scan the disk...
LOG_DIRS = %w(
  /private/var/log/
  /Library/Logs
)

ZIP_EXTENSIONS = %w(
  gz
  bz2
)

BINARY_EXTENSIONS = %w(
  asl
)

class LogFileWatcher
  attr_accessor(
    :binary_logs,
    :zipped_logs,
    :text_logs,
    :streamable_logs,
    :reader_threads
  )

  def initialize
    @log_files = LOG_DIRS.flat_map { |log_dir| Dir[File.join(log_dir, '**/*')] }.select { |f| File.file?(f) }
    (@binary_logs, @text_logs) = @log_files.partition { |f| BINARY_EXTENSIONS.include?(File.extname(f)[1..-1] ) }
    (@zipped_logs, @streamable_logs) = @text_logs.partition { |f| ZIP_EXTENSIONS.include?(File.extname(f)[1..-1]) }
  end

  # TODO: handle log rotation, .asl logs
  def read_log_streams(&block)
    @reader_threads = @streamable_logs.inject({}) do |memo, log_file|
      memo[log_file] = Thread.new do
        shell_command = "tail -f #{log_file}"
        lines_read = 0

        Open3.popen3(shell_command) do |_stdin, stdout, stderr, wait_thr|
          pid = wait_thr.pid
          Rails.logger.info("'#{shell_command}' child PID is #{pid}.")

          while(log_line = stdout.gets)
            #next if log_line.empty?
            yield(log_file, log_line, (lines_read += 1))
          end

          # TODO: Should be read continously
          Rails.logger.error("STDERR from '#{shell_command}: #{stderr.gets}")
        end
      end

      memo
    end
  end
end
