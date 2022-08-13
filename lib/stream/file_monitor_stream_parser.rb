require 'jsonpath'
require 'open3'
require 'pp'
require 'tty'


class FileMonitorStreamParser
  FILE_MONITOR_EXECUTABLE_DEFAULT_PATH = '/Applications/FileMonitor.app/Contents/MacOS/FileMonitor'
  FILE_MONITOR_VERSION = '1.3.0'
  STATS_PRINTOUT_INTERVAL_DEFAULT = 1000

  # Options:
  #   command_line_args: Array or String. args you want to pass to FileMonitor.
  #   file_monitor_path: String or Pathname. Defaults to FILE_MONITOR_EXECUTABLE_DEFAULT
  #   shell command: For a custom shell command
  def initialize(options = {})
    if Process.uid != 0 && options[:shell_command].nil?
      raise "You don't seem to be logged in as root, which is required to run File Monitor. Maybe try again with sudo."
    end

    command_line_args = options[:command_line_args]
    command_line_args = command_line_args.join(' ') if command_line_args.is_a?(Array)
    file_monitor_path = options[:file_monitor_path]&.to_s || FILE_MONITOR_EXECUTABLE_DEFAULT_PATH
    shell_command = options[:shell_command] || "#{file_monitor_path} #{command_line_args}"
    @shell_command_streamer = ShellCommandStreamer.new(shell_command)

    # Running totals
    @event_counts ||= Hash.new { |hash, key| hash[key] = Hash.new(0) }
  end

  # TODO: should be separated from parsing the FileMonitor call because it could be a file
  def parse_stream!(&block)
    @shell_command_streamer.stream! do |json|
      Rails.logger.debug("JSON: #{json}")
      next if json.empty?
      file_event = FileEvent.from_json(json)
      add_to_running_totals(file_event)
      yield(file_event)
    end
  end

  # Keep track of / print out some running totals... just counts
  def add_to_running_totals(file_event)
    FileEvent::JSON_PATHS.keys.each { |k| @event_counts[k][file_event[k]] += 1 }

    if @shell_command_streamer.lines_read_count % STATS_PRINTOUT_INTERVAL_DEFAULT == 0
      puts "Read #{@shell_command_streamer.lines_read_count} so far..."
      puts JSON.pretty_generate(@event_counts)
    end
  end
end
