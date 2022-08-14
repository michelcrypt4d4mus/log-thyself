require File.join(Rails.root, 'config', 'log_event_filters', 'filter_definitions')

class LogEventFilter
  FILTER_DEFINITIONS = FilterDefinitions::LOG_EVENT_FILTERS

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

    if @rule[:allowed?].call(event)
      true
    else
      Rails.logger.debug("Event blocked by filter '#{@rule[:comment]}'")
      false
    end
  end

  # Check the properties match before applying the proc
  def applicable?(event)
    @rule[:matchers].all? do |col_name, value|
      return false unless event[col_name]

      if value.is_a?(Array)
        value.include?(event[col_name])
      else
        value == event[col_name]
      end
    end
  end
end
