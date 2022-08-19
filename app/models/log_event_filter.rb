# Each filter defines a rule to block or allow events matching certain criteria.
# The class itself handles coordination of the set of all filter instances.

require 'tty-table'
require File.join(Rails.root, 'config', 'log_event_filters', 'filter_definitions')


class LogEventFilter < Struct.new(:rule)
  STATUSES = { true => :allowed, false => :blocked }
  BOOLEANS = STATUSES.keys

  class << self
    attr_accessor :filters, :filter_stats_logger
  end

  def self.build_filters!(options = {})
    FilterDefinitions.validate!
    @filters = FilterDefinitions::LOG_EVENT_FILTERS.map { |fd| new(fd) }
    Rails.logger.info("Built #{@filters.size} filters")
    @filter_stats_logger = FilterStatsLogger.new(options)
  end

  # All the filters must allow an event for it to be recorded / considered "allowed"
  def self.allow?(event)
    is_permitted = @filters.all? { |f| f.allow?(event) }
    @filter_stats_logger.increment_event_counts(event, STATUSES.fetch(is_permitted))
    is_permitted
  end

  def allow?(event)
    return true unless applicable?(event)

    # If :allowed? is a boolean use it directly to determine status
    # If it's a Proc call it and use the return value.
    if BOOLEANS.include?(rule[:allowed?])
      rule[:allowed?]
    else
      rule[:allowed?].call(event)
    end
  end

  # Check the property matcher before applying the :allowed? rule
  def applicable?(event)
    rule[:matchers].all? do |col_name, match_rule|
      return false unless event[col_name]

      if match_rule.is_a?(Array)
        match_rule.any? { |matcher| value_match?(matcher, event[col_name]) }
      else
        value_match?(match_rule, event[col_name])
      end
    end
  end

  private

  def value_match?(matcher, value)
    matcher.is_a?(Regexp) ? matcher.match?(value) : matcher == value
  end

  def pastel
    self.class.pastel
  end
end
