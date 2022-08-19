# Spawns a shell process and reads the output, calling yield() on each line
#
# STDERR output will be read/drained with a separate thread and printed directly to
# the application logs at ERROR level. The assumption is you want to focus on STDOUT
# and the only real reason to read STDERR is to prevent the buffer from filling up and
# crashing the program.

require 'open3'


class ShellCommandStreamer
  attr_accessor :lines_read_count

  def initialize(shell_command)
    @shell_command = shell_command
    @lines_read_count = 0
    Rails.logger.info(self.class.to_s + ": shell command is '#{@shell_command}'")
  end

  # Yields a tuple: (line, lines_read_count)
  # Yielded lines have the trailing newline removed.
  # spawn_stderr_reader causes a thread to be spawned to read from STDERR and log (as errors) to Rails log
  def stream!(spawn_stderr_reader: true, &block)
    stderr_thread = nil

    begin
      Open3.popen3(@shell_command) do |_stdin, stdout, stderr, thread|
        child_pid = thread.pid
        @child_process_string = "Child process '#{@shell_command}' (PID: #{child_pid})"
        stderr_thread = start_stderr_reader_thread(stderr) if spawn_stderr_reader
        Rails.logger.info("#{@child_process_string} started...")

        while(line = stdout.gets) do
          line.chomp!
          @lines_read_count = stdout.lineno
          Rails.logger.debug("Stream line #{@lines_read_count}: #{line}")
          yield(line, @lines_read_count)
        end
      end
    rescue Errno::EACCES => e
      Rails.logger.error("You don't have permission to read '#{@shell_command}' (maybe try with sudo)\n")
      raise
    ensure
      if stderr_thread
        stderr_thread.kill
        sleep 0.01 while stderr_thread.alive?
        Rails.logger.debug("STDERR thread for '#{@shell_command}' killed successfully")
      end
    end
  end

  # Slurps the whole stream
  def read
    contents = ''
    stream! { |line| contents += line + "\n" }
    contents
  end

  private

  def start_stderr_reader_thread(stderr)
    Thread.new do
      begin
        while(line = stderr.gets) do
          log_stderr_output(line)
        end
      rescue IOError => e
        raise e unless e.message == "stream closed in another thread"
      end
    end
  end

  def log_stderr_output(line)
    Rails.logger.warn("#{@child_process_string} STDERR: #{line}")
  end
end

