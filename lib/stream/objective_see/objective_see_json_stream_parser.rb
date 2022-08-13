# Base class for Objective-See related streams
require 'pp'


class ObjectiveSeeJsonStreamParser
  STATS_PRINTOUT_INTERVAL_DEFAULT = 1000

  # Options:
  #   command_line_args: args you want to pass to the executable.
  #   model_klass: model you want to save to. Defaults to inference based on the executable_path
  #   stats_printout_interval: How many events will pass between stats printouts
  def initialize(executable_path, options = {})
    raise "You don't have root privileges. Maybe try again with sudo." if Process.uid != 0
    raise "You don't seem to have an executable at #{executable_path}" unless File.exist?(executable_path)

    @executable_path = executable_path
    shell_command = "#{@executable_path} #{options[:command_line_args]}"
    @shell_command_streamer = ShellCommandStreamer.new(shell_command)
    @executable_basename = File.basename(@executable_path)
    @model_klass = options[:model_klass] || @executable_basename.sub('Monitor', 'Event').constantize

    # Running totals
    @stats_printout_interval = options[:stats_printout_interval] || STATS_PRINTOUT_INTERVAL_DEFAULT
    @event_counts ||= Hash.new { |hash, key| hash[key] = Hash.new(0) }

    if self.class::EXECUTABLE_VERSION != executable_version
      puts "WARNING: log-thyself was tested against #{@executable_basename} version #{self.class::EXECUTABLE_VERSION}"
      puts "         You are running #{executable_version}"
    end
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
      pp @event_counts
    end
  end

  def executable_help_message
    `#{@executable_path} -h`
  end

  def executable_version
    if executable_help_message =~ /#{@executable_basename} \(v(\d+\.\d+\.\d+)\)/
      $1
    end
  end
end
