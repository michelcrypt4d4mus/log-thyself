# Base class for collector commands

require 'shared_methods'

# Options common to all tasks
class CommonCommand < Thor
  class_option :app_log_level,
                desc: "This application's logging verbosity",
                enum: Logger::Severity.constants.map(&:to_s).sort_by { |l| "Logger::#{l}".constantize },
                default: 'INFO',
                banner: 'LEVEL'
end

# Options common to all collect: commands
class CollectorCommand < CommonCommand
  class_option :avoid_dupes,
                desc: '[WIP, not 100% functional] Attempt to avoid dupes by going a lot slower',
                type: :boolean,
                default: false

  class_option :read_only,
                desc: "Just read and process the streams, don't save to the database",
                type: :boolean,
                default: false

  class_option :disable_filters,
                desc: "Disable the filters",
                type: :boolean,
                default: false

  class_option :filter_stats_logging_frequency,
                desc: "How often should the summary tables be printed (0 means never)",
                type: :numeric,
                default: FilterStatsLogger::DEFAULT_FILTER_STATS_LOGGING_FREQUENCY

  no_commands do
    def make_announcement
      say "\n🌀 Summoning log vortex...🌀\n", :cyan
      say "      (CTRL-C to stop)\n\n"
    end
  end

  # Thor complains if this is not defined and there's an error
  def self.exit_on_failure?
    true
  end
end
