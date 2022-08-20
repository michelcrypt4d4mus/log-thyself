# Coordinates a bunch of filters

class FilterSet
  class << self
    attr_accessor :filters, :filter_stats_logger
  end

  def initialize(filter_definitions, options = {})
    @filters = filter_definitions.map { |fd| LogEventFilter.new(fd) }
    Rails.logger.info("Built #{@filters.size} filters")
    @filter_stats_logger = FilterStatsLogger.new(options)
  end

  # All the filters must allow an event for it to be recorded / considered "allowed"
  def allow?(event)
    is_permitted = @filters.all? { |f| f.allow?(event) }
    @filter_stats_logger.increment_event_counts(event, LogEventFilter::STATUSES.fetch(is_permitted))
    is_permitted
  end
end
