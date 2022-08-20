# Each filter defines a rule to block or allow events matching certain criteria.
# The class itself handles coordination of the set of all filter instances.

require 'tty-table'
# require File.join(Rails.root, 'config', 'log_event_filters', 'filter_definitions')
# require File.join(Rails.root, 'config', 'log_event_filters', 'objective_see_event_filter_definitions')


class LogEventFilter < Struct.new(:rule)
  STATUSES = { true => :allowed, false => :blocked }

  def allow?(event)
    return true unless applicable?(event)

    # If :allowed? is a boolean use it directly to determine status
    # If it's a Proc call it and use the return value.
    if STATUSES.keys.include?(rule[:allowed?])
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
