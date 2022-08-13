# Use Oj gem to parse the log stream (just an array of hashes) in JSON format.
# TODO: Use separate thread to read STDERR
# TODO: Rename to AppleJsonLogStreamParser

require 'io/wait'
require 'oj'
require 'open3'


class JsonStreamParser < ::Oj::ScHandler
  LOG_STREAM_SHELL_CMD = "log stream --source --style json"
  LOG_SHOW = "log show --color none --style json"
  LOG_LEVELS = %w(default info debug)

  def initialize(shell_command)
    @shell_command = shell_command
  end

  # Reads the stream output of shell_command and yields MacOsSystemLog objects to block
  def parse_stream!(&block)
    pid = nil

    begin
      Open3.popen3(@shell_command) do |_stdin, stdout, stderr, wait_thr|
        pid = wait_thr.pid
        Rails.logger.info("Streaming process '#{@shell_command}' running as child with process ID #{pid}.")

        json_parse = Enumerator.new do |yielder|
          process_stream(stdout) do |parsed_chunk|
            yielder << parsed_chunk
          end
        end

        json_parse.each do |log_json|
          yield(MacOsSystemLog.from_json(log_json))

          if stderr.ready?
            error_line = stderr.gets&.chomp
            Rails.logger.error("Shell stderr output: #{error_line}") unless error_line.blank?
          end
        end
      end
    ensure
      msg = "Killing child process with PID #{pid} and loading final batch of messages..."
      Rails.logger.warn(msg)
      puts msg
    end
  end

  def process_stream(io_stream, &block)
    @yielder = block
    Oj.sc_parse(self, io_stream)
  end

  # Oj::ScHandler callbacks beyond here
  def array_start
    []
  end

  def hash_start()
    {}
  end

  def hash_set(h,k,v)
    h[k] = v
  end

  # Signals parsing is complete
  def add_value(value)
    Rails.logger.info("Finished parsing: #{value}")
  end

  def array_append(arr, value)
    # Avoid building an enormous array of the entire stream; just yield it.
    if value.is_a?(Hash) && value.has_key?('traceID')
      @yielder.call(value)
      return
    end

    arr << value
  end
end
