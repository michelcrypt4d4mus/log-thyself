require File.join(Rails.root, 'config', 'log_event_filters', 'filter_definitions')
require 'pp'

class LogEventFilter
  include ActionView::Helpers::NumberHelper

  BOOLEANS = [true, false]
  STATUSES = %i[allowed blocked]

  # Constants for formatting the log output.
  STATS_INDENT = 15
  DEFAULT_FILTER_STATS_LOGGING_FREQUENCY = 50_000
  STATS_TABLE_HEADER = %w[process_name events allowed blocked allow_pct block_pct].map(&:upcase)

  class << self
    attr_accessor :blocked_event_counts, :event_counts, :filters, :pastel
  end

  attr_reader :rule

  def self.build_filters!(options = {})
    FilterDefinitions.validate!
    @filters = FilterDefinitions::LOG_EVENT_FILTERS.map { |fd| new(fd) }
    Rails.logger.info("Built #{@filters.size} filters")

    # A missing key yields a hash with zeroes preloaded for the STATUSES keys
    @event_counts = Hash.new { |hsh, process| hsh[process] = { allowed: 0, blocked: 0 } }
    @filter_stats_logging_frequency = options[:filter_stats_logging_frequency] || DEFAULT_FILTER_STATS_LOGGING_FREQUENCY
    @pastel = Pastel.new
  end

  # All the filters must allow an event for it to be recorded / considered "allowed"
  def self.allow?(event)
    is_permitted = @filters.all? { |f| f.allow?(event) }
    increment_event_counts(event, is_permitted ? :allowed : :blocked)
    is_permitted
  end

  def self.increment_event_counts(event, status)
    @event_counts[event[:process_name]][status] += 1
    log_stats if total_events % @filter_stats_logging_frequency == 0
  end

  # If status is nil then just get the overall total
  def self.total_events(status = nil)
    @event_counts.inject(0) do |total, (_process, counts)|
      total + (status.nil? ? counts.values.sum : counts[status])
    end
  end

  # Class methods above 👆 instance methods below 👇

  def initialize(rule)
    @rule = rule
  end

  def allow?(event)
    return true unless applicable?(event)

    # If :allowed? is a boolean use it directly to determine status
    # If it's a Proc call it and use the return value.
    if BOOLEANS.include?(@rule[:allowed?])
      @rule[:allowed?]
    else
      @rule[:allowed?].call(event)
    end
  end

  # Check the property matcher before applying the :allowed? rule
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

  # Render a table to the log plus allow/block rates etc
  def self.log_stats
    # Compute totals row
    totals = STATUSES.inject({}) do |hsh, status|
      hsh[status] = {
        count: total_events(status),
        pct: (100 * total_events(status).to_f / total_events).round(1).to_s + '%'
      }

      hsh
    end

    totals_row = [
      pastel.bold('Total Event Count'),
      total_events,
      totals[:allowed][:count],
      totals[:blocked][:count],
      totals[:allowed][:pct],
      totals[:blocked][:pct]
    ]

    # Each row corresponds to a proc and has 6 cols, ordered by event count
    # process, total_count, allowed_count, blocked_count, allowed_pct, blocked_pct
    # TODO use rails number_to_pct styler
    sorted_processes = @event_counts.keys.sort_by { |process| @event_counts[process].values.sum }

    table_rows = sorted_processes.reverse.inject([]) do |rows, process|
      counts = STATUSES.map { |status| @event_counts[process][status] }
      total_for_proc = counts.sum
      percentages = counts.map { |c| "#{(100 * c.to_f / total_for_proc).round(1)}%" }
      rows << [process, total_for_proc] + counts + percentages
    end

    # Style the table with a blank line above and below the total event counts row
    buffer_row = Array.new(6) { |_| '' }
    table_rows = [buffer_row, totals_row, buffer_row] + table_rows
    table = TTY::Table.new(header: STATS_TABLE_HEADER, rows: table_rows)
    aligns = [:left] + Array.new(5) { |_| :right }

    table_txt = table.render(:unicode, padding: [0, 1], alignments: aligns) do |renderer|
      renderer.filter = ->(val, row_index, col_index) do
        if row_index == 0
          pastel.bright_white(val)
        elsif row_index <= 3
          pastel.white.inverse(val)
        elsif row_index % 2 == 1
          pastel.black.on_white(val)
        else
          pastel.white(val)
        end
      end
    end

    # TODO: use the "say and log"
    msg = "\n\n" + (' ' * STATS_INDENT)
    msg += pastel.underline("Allowed / Blocked Event Counts By Process\n") + table_txt
    Rails.logger.info(msg)
    puts msg
  end

  def value_match?(matcher, value)
    matcher.is_a?(Regexp) ? matcher.match?(value) : matcher == value
  end

  def pastel
    self.class.pastel
  end
end
