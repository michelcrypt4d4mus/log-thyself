# Base class for Objective-See related streams.
# Table to be written will be inferred from the executable (e.g. ProcessMonitor.app writes to process_events table)
#
# Subclasses should define these constants:
#     EXECUTABLE_PATH_DEFAULT (e.g. '/Applications/FileMonitor.app/Contents/MacOS/FileMonitor')
#     EXECUTABLE_VERSION (e.g. '1.3.0')

require 'pp'


class ObjectiveSeeJsonStreamParser
  STATS_PRINTOUT_INTERVAL_DEFAULT = 1000

  # Options:
  #   command_line_args: args you want to pass to the executable.
  #   read_from_file: read from the specified file path instead of a stream
  #   stats_printout_interval: How many events will pass between stats printouts
  def initialize(executable_path, options = {})
    Rails.logger.debug("#{self.class.to_s} instantiated with options: #{options}")
    @executable_path = executable_path || EXECUTABLE_PATH_DEFAULT
    @executable_basename = File.basename(@executable_path)
    @model_klass = @executable_basename.sub('Monitor', 'Event').constantize
    @shell_command_streamer = ShellCommandStreamer.new(build_shell_command(options))

    # Running totals
    @stats_printout_interval = options[:stats_printout_interval] || STATS_PRINTOUT_INTERVAL_DEFAULT
    @event_counts ||= Hash.new { |hash, key| hash[key] = Hash.new(0) }
  end

  def parse_stream!(&block)
    @shell_command_streamer.stream! do |json|
      Rails.logger.debug("JSON: #{json}")
      next if json.empty?
      event = @model_klass.from_json(json)
      next if event.nil?
      add_to_running_totals(event)
      yield(event)
    end
  end

  def executable_help_message
    `#{@executable_path} -h`
  end

  def executable_version
    version_regex = /#{@executable_basename} \(v(\d+\.\d+\.\d+)\)/
    (executable_help_message =~ version_regex) && Regexp.last_match(1)
  end

  private

  # Keep track of / print out some running totals... just counts, nothing fancy.
  def add_to_running_totals(event)
    @model_klass::JSON_PATHS.keys.each { |k| @event_counts[k][event[k]] += 1 }

    # if @shell_command_streamer.lines_read_count % @stats_printout_interval == 0
    #   puts "[#{@model_klass.to_s}] Read #{@shell_command_streamer.lines_read_count}..."
    #   pp @event_counts  TODO: some kind of better status
    # end
  end

  def build_shell_command(options)
    if (read_from_file = options[:read_from_file])
      raise ArgumentError.new("'#{read_from_file}' is not a file") unless File.exist?(read_from_file)
      return "cat \"#{read_from_file}\""
    end

    raise "You don't have root privileges. Maybe try again with sudo." if Process.uid != 0
    raise "You don't seem to have an executable at #{@executable_path}" unless File.exist?(@executable_path)

    if self.class::EXECUTABLE_VERSION != executable_version
      puts "WARNING: log-thyself was tested against #{@executable_basename} version #{self.class::EXECUTABLE_VERSION}"
      puts "         You are running #{executable_version}"
    end

    "#{@executable_path} #{options[:command_line_args]}"
  end
end
