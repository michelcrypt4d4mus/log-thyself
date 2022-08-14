require File.join(Rails.root, 'config', 'log_event_filters', 'filter_definitions')

class LogEventFilter
  FILTER_DEFINITIONS = FilterDefinitions::LOG_EVENT_FILTERS
  BOOLEANS = [true, false]

  def self.build_filters!
    FilterDefinitions.validate!
    @filters = FILTER_DEFINITIONS.map { |fd| new(fd) }
    Rails.logger.info("Built #{@filters.size} filters")
  end

  # All must allow an event for event to be recorded
  def self.allow?(event)
    @filters.all? { |f| f.allow?(event) }
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
