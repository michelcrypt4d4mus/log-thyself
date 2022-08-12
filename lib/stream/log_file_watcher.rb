# Watches logs from the old file system
require 'open3'




class LogFileWatcher
  attr_accessor :open_logs, :closed_logs, :streamer_threads

  def initialize
    (@open_logs, @closed_logs) = @logfiles.partition { |logfile| !logfile.closed? }
  end

  # TODO: handle log rotation, .asl logs
  def read_log_streams(&block)
    @streamer_threads = @open_logs.inject({}) do |memo, log_file|
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

  private

  # Zipped logs are considered closed; we don't need a thread to keep reading them
  def collect_closed_logs

  end
end
