require File.join(Rails.root, 'config', 'log_event_filters', 'filter_definitions')

class LogEventFilter
  FILTER_DEFINITIONS = FilterDefinitions::LOG_EVENT_FILTERS
  BOOLEANS = [true, false]

  class << self
    attr_accessor :blocked_event_counts, :filters
  end

  def self.build_filters!
    FilterDefinitions.validate!
    @filters = FILTER_DEFINITIONS.map { |fd| new(fd) }
    Rails.logger.info("Built #{@filters.size} filters")
    @blocked_event_counts = Hash.new(0)
    @allowed_event_count = 0
  end

  # All must allow an event for event to be recorded
  def self.allow?(event)
    @allowed_event_count += 1
    @filters.all? { |f| f.allow?(event) }
  end

  def self.increment_blocked_event_counts(event)
    @blocked_event_counts[event[:process_name]] += 1
    blocked_event_count = @blocked_event_counts.values.sum
    return unless blocked_event_count % 5000 == 0

    # Render a table to the log
    rows = @blocked_event_counts.to_a.sort_by { |row| row[1] }.reverse
    table = TTY::Table.new(header: %w[filtered_process count], rows: rows).render(:unicode, indent: 5)
    Rails.logger.info("Allowed #{@allowed_event_count} / Blocked #{blocked_event_count} events. Blocked event counts:\n#{table}")
  end

  def initialize(rule)
    @rule = rule
  end

  def allow?(event)
    return true unless applicable?(event)
    permitted = BOOLEANS.include?(@rule[:allowed?]) ? @rule[:allowed?] : @rule[:allowed?].call(event)

    if permitted
      true
    else
      Rails.logger.debug("Event blocked by filter '#{@rule[:comment]}'")
      self.class.increment_blocked_event_counts(event)
      false
    end
  end

  # Check the properties match before applying the proc
  def applicable?(event)
    @rule[:matchers].all? do |col_name, match_rule|
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
end
