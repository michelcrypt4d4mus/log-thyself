require 'jsonpath'
require 'open3'
require 'pp'
require 'tty'


class ObjectiveSeeJsonStreamParser
  STATS_PRINTOUT_INTERVAL_DEFAULT = 1000

  # Options:
  #   command_line_args: Array or String. args you want to pass to the executable.
  #   model_klass: model you want to save to. defaults to inference based on the executable_path
  #   shell command: For a custom shell command
  #   stats_printout_interval: How many events will pass between stats printouts
  def initialize(executable_path, options = {})
    if Process.uid != 0 && options[:shell_command].nil?
      raise "You don't seem to be logged in as root, which is required to run File Monitor. Maybe try again with sudo."
    end

    command_line_args = options[:command_line_args]
    command_line_args = command_line_args.join(' ') if command_line_args.is_a?(Array)
    shell_command = options[:shell_command] || "#{executable_path} #{command_line_args}"
    @shell_command_streamer = ShellCommandStreamer.new(shell_command)
    @model_klass = options[:model_klass] || executable_path.split('/').last.sub('Monitor', 'Event').constantize
    @debug = options[:debug]

    # Running totals
    @stats_printout_interval = options[:stats_printout_interval] || STATS_PRINTOUT_INTERVAL_DEFAULT
    @event_counts ||= Hash.new { |hash, key| hash[key] = Hash.new(0) }
  end

  # TODO: should be separated from parsing the executable call because it could be a file
  def parse_stream!(&block)
    @shell_command_streamer.stream! do |json|
      Rails.logger.debug("JSON: #{json}")
      next if json.empty?
      event = @model_klass.from_json(json)
      add_to_running_totals(event)
      yield(event)
    end
  end

  # Keep track of / print out some running totals... just counts
  def add_to_running_totals(event)
    @model_klass::JSON_PATHS.keys.each { |k| @event_counts[k][event[k]] += 1 }

    if @shell_command_streamer.lines_read_count % @stats_printout_interval == 0
      puts "Read #{@shell_command_streamer.lines_read_count} so far..."
      puts JSON.pretty_generate(@event_counts)
    end
  end
end
