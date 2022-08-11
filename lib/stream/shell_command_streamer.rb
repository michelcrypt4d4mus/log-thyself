# Call with a block; it will yield() non blannk lines read from the STDOUT of the
# :shell_command execution.
#
# STDERR output will be read/drained with a separate thread and printed directly to
# the application logs at ERROR level. The assumption is you want to focus on STDOUT
# and the only real reason to read STDERR is to prevent the buffer from filling up and
# crashing the program.

require 'open3'


class ShellCommandStreamer
  attr_accessor :lines_yielded_count, :lines_read_count

  def initialize(shell_command)
    @shell_command = shell_command
    @lines_yielded_count = @lines_read_count = 0
  end

  def stream!
    Open3.popen3(@shell_command) do |_stdin, stdout, stderr, thread|
      child_pid = thread.pid
      @child_process_string = "Child process '#{@shell_command}' (PID: #{child_pid})"
      Rails.logger.info("#{@child_process_string} started...")
      start_stderr_reader_thread(stderr)

      # Start reading
      while(stdout_line = stdout.gets) do
        @lines_read_count += 1
        next if stdout_line.blank?
        yield(stdout_line)
        @lines_yielded_count += 1
      end
    end
  end

  private

  def start_stderr_reader_thread(stderr)
    Thread.new do
      begin
        while(stderr_line = stderr.gets) do
          log_stderr_output(stderr_line)
        end
      ensure
        begin
          log_stderr_output(stderr.read_non_block(10_000)) unless stderr_line.blank?
        rescue IO::EAGAINWaitReadable
          Rails.logger.debug("#{child_process_string} STDERR buffer drained")
        end
      end
    end
  end

  def log_stderr_line(stderr_line)
    Rails.logger.error("#{child_process_string} STDERR: #{line}")
  end
end

