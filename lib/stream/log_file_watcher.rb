# Watches logs from the old file system
require 'open3'


# TODO we could scan the disk...
LOG_DIRS = %w(
  /private/var/log/
  /Library/Logs
)


class LogFileWatcher
  attr_accessor :open_logs, :closed_logs, :streamer_threads

  def initialize
    @logfiles = LOG_DIRS.flat_map { |dir| Dir[File.join(dir, '**/*')] }.select { |f| File.file?(f) }.map do |file|
      Logfile.new(file_path: file)
    end

    (@open_logs, @closed_logs) = @logfiles.partition { |logfile| !logfile.closed? }
  end

  # TODO: handle log rotation, .asl logs
  def read_log_streams(&block)
    raise 'more closed logs!'
    #aslmanager.20220811T021729-04
    #2022.08.09.asl coming back open
    # Analytics-90Day-2022-08-08-200000.0003.core_analytics (diagnostics folder)

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
