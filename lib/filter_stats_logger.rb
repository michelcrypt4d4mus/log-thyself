require 'pastel'


class FilterStatsLogger
  include ActionView::Helpers::NumberHelper
  include StyledNotifications
  include TableLogger

  # allowed vs. blocked
  STATUS_LABELS = LogEventFilter::STATUSES.values

  # Constants related to formatting the output
  STATS_TITLE_INDENT = 15
  TOTAL_EVENT_COUNT = 'Total Event Count'
  DEFAULT_FILTER_STATS_LOGGING_FREQUENCY = 50_000
  STATS_TABLE_HEADER = %w[process_name events allowed blocked allow_pct block_pct].map(&:upcase)
  TABLE_ALIGNMENTS = [:left] + Array.new(5) { |_| :right }
  BUFFER_ROW = Array.new(6) { |_| '' }

  attr_accessor :event_counts

  def initialize(options = {})
    # A missing key yields a hash with zeroes preloaded for the STATUSES keys
    @event_counts = Hash.new { |hsh, process| hsh[process] = { allowed: 0, blocked: 0 } }
    @filter_stats_logging_frequency = options[:filter_stats_logging_frequency] || DEFAULT_FILTER_STATS_LOGGING_FREQUENCY
    @pastel = Pastel.new
  end

  def increment_event_counts(event, status)
    @event_counts[event[:process_name]][status] += 1

    if (@filter_stats_logging_frequency > 0) && (total_events % @filter_stats_logging_frequency == 0)
      log_stats
    end
  end

  # If status is nil then just get the overall total
  def total_events(status = nil)
    @event_counts.inject(0) do |total, (_process, counts)|
      total + (status.nil? ? counts.values.sum : counts[status])
    end
  end


  # Render a table to the log plus allow/block rates etc
  def log_stats
    # Compute totals row
    totals = STATUS_LABELS.inject({}) do |hsh, status|
      hsh[status] = {
        count: total_events(status),
        pct: (100 * total_events(status).to_f / total_events).round(1).to_s + '%'
      }

      hsh
    end

    totals_row = [
      pastel.bold(TOTAL_EVENT_COUNT),
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

    # Style the table with a blank line above and below the total event counts row
    table_rows = [BUFFER_ROW, totals_row, BUFFER_ROW] + sorted_processes.reverse.inject([]) do |rows, process|
      counts = STATUS_LABELS.map { |status| @event_counts[process][status] }
      total_for_proc = counts.sum
      percentages = counts.map { |c| "#{(100 * c.to_f / total_for_proc).round(1)}%" }
      rows << [process, total_for_proc] + counts + percentages
    end

    table = TTY::Table.new(header: STATS_TABLE_HEADER, rows: table_rows)
    table.orientation = :horizontal

    table_txt = table.render(:unicode, padding: [0, 1], alignments: TABLE_ALIGNMENTS, **table_render_options) do |renderer|
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

    msg = "\n\n" + (' ' * STATS_TITLE_INDENT)
    msg += pastel.underline("Allowed / Blocked Event Counts By Process\n")
    msg += table_txt + "\n\n"
    say_and_log(msg)
  end
end
