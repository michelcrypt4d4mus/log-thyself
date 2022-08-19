# Use Oj gem to parse the log stream (just an array of hashes) in JSON format.

require 'dotenv'
require 'io/wait'
require 'oj'
require 'open3'

Dotenv.load(File.join(Rails.root, '.env'))


class AppleJsonLogStreamParser < ::Oj::ScHandler
  include StyledNotifications

  # Options for log command
  LOG_LEVELS = %w(default info debug)
  LOG_OPTIONS = '--source --style json --color none'
  LOG_EXECUTABLE_PATH = ENV['LOG_EXECUTABLE_PATH'].presence || 'log'
  LOG_STREAM_SHELL_CMD = "#{LOG_EXECUTABLE_PATH} stream #{LOG_OPTIONS}"
  LOG_SHOW_SHELL_CMD = "#{LOG_EXECUTABLE_PATH} show #{LOG_OPTIONS} --debug --info"

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
      say_and_log("Killing child process with PID #{pid} and loading final batch of messages...")
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
