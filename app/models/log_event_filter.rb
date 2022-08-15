require File.join(Rails.root, 'config', 'log_event_filters', 'filter_definitions')
require 'pp'

class LogEventFilter
  include ActionView::Helpers::NumberHelper

  FILTER_DEFINITIONS = FilterDefinitions::LOG_EVENT_FILTERS
  STATS_LOGGING_FREQUENCY = 25000
  BOOLEANS = [true, false]

  class << self
    attr_accessor :blocked_event_counts, :filters, :pastel
  end

  attr_reader :rule

  def self.build_filters!
    FilterDefinitions.validate!
    @filters = FILTER_DEFINITIONS.map { |fd| new(fd) }
    Rails.logger.info("Built #{@filters.size} filters")
    @event_counts = h = Hash.new { |h, k| h[k] = { allowed: 0, blocked: 0 } }
    @total_events = 0
    @pastel = Pastel.new
  end

  # All must allow an event for event to be recorded
  def self.allow?(event)
    permitted = @filters.all? { |f| f.allow?(event) }
    increment_event_counts(event, permitted ? :allowed : :blocked)
    permitted
  end

  def self.increment_event_counts(event, status)
    @total_events += 1
    @event_counts[event[:process_name]][status] += 1
    log_stats if @total_events % STATS_LOGGING_FREQUENCY == 0
  end

  def self.sum_event_counts(permitted)
    @event_counts.inject(0) { |event_count, (_, counts)| event_count + counts[permitted ? :allowed : :blocked] }
  end

  # Render a table to the log plus allow/block rates etc
  def self.log_stats
    allowed_total = sum_event_counts(true)
    blocked_total = sum_event_counts(false)

    # Order procs by most event_count
    sorted_processes = @event_counts.keys.sort_by { |process| @event_counts[process].values.sum }

    rows = sorted_processes.reverse.inject([]) do |memo, process|
      counts = %i[allowed blocked].map { |status| @event_counts[process][status] }
      total_for_proc = counts.sum
      percentages = counts.map { |c| "#{(100 * c.to_f / total_for_proc).round(1)}%" }
      memo << [process, total_for_proc] + counts + percentages
    end

    total_allow_pct = (100 * allowed_total.to_f / @total_events).round(1).to_s + '%'
    total_block_pct = (100 * blocked_total.to_f / @total_events).round(1).to_s + '%'

    header = %w[process_name events allowed blocked allow_pct block_pct]
    totals_row = [pastel.bold('TOTAL'), @total_events, allowed_total, blocked_total, total_allow_pct, total_block_pct]
    buffer_row = Array.new(6) { |_| '' }
    table = TTY::Table.new(header: header, rows: [buffer_row, totals_row, buffer_row] + rows)
    aligns = [:left] + Array.new(5) { |_| :right }

    table_txt = table.render(:unicode, indent: 5, padding: [0, 1], alignments: aligns) do |renderer|
      renderer.filter = ->(val, row_index, col_index) do
        if row_index == 1
          pastel.bold.bright_white(val)
        elsif row_index < 2
          val
        elsif row_index == 2
          pastel.bright_white.on_black(val)
        elsif row_index % 2 == 0
          pastel.black.on_white(val)
        else
          pastel.white.on_black(val)
        end
      end
    end

    Rails.logger.info("Filtered event counts:\n#{table_txt}")
  end

  def initialize(rule)
    @rule = rule
  end

  def allow?(event)
    return true unless applicable?(event)
    BOOLEANS.include?(@rule[:allowed?]) ? @rule[:allowed?] : @rule[:allowed?].call(event)
    # msg = sprintf("%5s / %5s", applicable, (permitted.nil? ? pastel.dim('<nil>') : permitted))
    # msg += sprintf("   %25s   %25s", pastel.red(event[:process_name]), pastel.blue(event[:sender_process_name]))
    # msg += sprintf("  %8s   %90s", pastel.green(event[:message_type]), pastel.magenta(event[:event_message]))
    # puts msg
    # applicable ? permitted : true
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

  def pastel
    self.class.pastel
  end
end
