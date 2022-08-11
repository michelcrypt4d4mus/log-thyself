require 'open3'


class SyslogStreamParser
  SUBSYSTEM_REGEX = /\[(\w+[.:]\w[-().: \w]*?)\]/.freeze  # e.g. 'com.apple.foobar.fugazi'
  SENDER_PROCESS_REGEX = /\(([._0-9A-Za-z]+)\)/.freeze
  DB_DATE_FORMAT = /^\s*\d{4}-\d{2}-\d{2}\s/.freeze
  HEX_COLS = [:activity_identifier, :thread_id]
  MAX_LINES_FOR_ONE_LOG_MESSAGE = 100

  # Apple uses shorter names in the syslogs than in the JSON
  EVENT_TYPE_MAPPING = {
    Activity: 'activityCreateEvent',
    State: 'stateEvent',
    Timesync: 'timesyncEvent',
    UserAction: 'userActionEvent'
  }

  # Up to :process_description are space delimited fields in Mac's log format. :process_description
  # requires further parsing. ORDER MATTERS! Must match order in log files.
  FIELD_NAMES_IN_FILE = %i(
    log_timestamp
    timestamp_without_date
    thread_id
    log_type
    activity_identifier
    process_id
    ttl
    process_description
  )

  # Only meant to be
  def initialize(log_file)
    @shell_command_streamer = ShellCommandStreamer.new("cat #{log_file}")
  end

  # Calls yield() with MacOsSystemLog objects
  def parse_shell_command_stream(&block)
    already_found_first_good_line_flag = false
    lines_in_this_log_message_count = 0
    current_log_entry = ''

    @shell_command_streamer.stream! do |log_line|
      log_line = log_line.chomp.force_encoding(Encoding::UTF_8)
      # Skip lines until we find one that looks valid (there's often cruft at the start of the output)
      unless already_found_first_good_line_flag
        next unless log_line =~ DB_DATE_FORMAT

        # We are storing the next line to be parsed in :current_log_entry until we can be sure
        # we have read the entire entry, which can span many lines.
        already_found_first_good_line_flag = true
        current_log_entry = log_line
        next
      end

      # Wait for the next datetime stamped row to decide we have the whole log entry assembled
      # in the :current_log_entry variable, at which point we process.
      if log_line =~ DB_DATE_FORMAT
        yield(MacOsSystemLog.new(process_log_entry(current_log_entry)))

        # Reset :current_log_entry and :lines_in_this_log_message_count
        current_log_entry = log_line
        lines_in_this_log_message_count = 1
      else
        current_log_entry += " #{log_line}"  # Replace newline with a space
        lines_in_this_log_message_count += 1

        # Start throwing warnings if the entry seems too big
        if lines_in_this_log_message_count > MAX_LINES_FOR_ONE_LOG_MESSAGE
          many_lines_warning = "Log entry spans #{lines_in_this_log_message_count} lines so far.\n\n"
          many_lines_warning += "Entry: #{current_log_entry}\n\ncurrent line: #{log_line}"
          Rails.logger.warn(many_lines_warning)
        end
      end
    end
  end

  def process_log_entry(log_entry)
    Rails.logger.debug("process_log_entry: #{log_entry}\n")
    row_values = log_entry.strip.split(' ', FIELD_NAMES_IN_FILE.size).map(&:strip)
    row = Hash[FIELD_NAMES_IN_FILE.zip(row_values)]

    # message and event type are unified in syslog but different fields in the JSON (and our DB)
    row[:message_type] = row[:log_type] if MacOsSystemLog::LOGGING_LEVELS.include?(row[:log_type])
    row[:event_type] = to_event_type(row[:log_type])
    row.delete(:log_type)

    if row[:process_id] !~ /\d+/
      Rails.logger.error("Invalid PID #{row[:process_id]}:\n  log_entry: #{log_entry}\n  row: #{row.pretty_inspect}")
      row[:process_id] = nil
    end

    # Process hexadecimal
    HEX_COLS.each { |hex_col| row[hex_col] = hex_to_int(row[hex_col]) }

    # Re-unify the timestamp cols
    row[:log_timestamp] = "#{row[:log_timestamp]} #{row[:timestamp_without_date]}"
    row.delete(:timestamp_without_date)
    extract_process_info(row)
  end

  private

  # A lot of info lives in a section of the log entry that is only semi-standardized/extractable
  def extract_process_info(row)
    return row if row[:process_description].blank?
    (row[:process_name], process_description) = row[:process_description].split(': ', 2).map(&:strip)
    return row if process_description.blank?

    sender_subsystem_msg = case process_description
      when /#{SENDER_PROCESS_REGEX}\s{1,5}#{SUBSYSTEM_REGEX}\s+(.*)/
        [$1, $2, $3]
      when /^\s*#{SUBSYSTEM_REGEX}\s+(.*)/
        [nil, $1, $2]
      when /^\s*#{SENDER_PROCESS_REGEX}\s+(.*)/
        [$1, nil, $2]
      else
        Rails.logger.debug("Failed to parse process info from '#{process_description}'")
        [nil, nil, process_description]
      end

    sender_subsystem_msg.map! { |v| v&.strip }
    (row[:sender_process_name], subsystem_category, row[:event_message]) = sender_subsystem_msg
    (row[:subsystem], row[:category]) = subsystem_category&.split(':', 2)
    row[:event_message]&.gsub!(/\s+/, ' ')
    row.except(:process_description, :ttl)
  end

  def to_event_type(log_type)
    return 'logEvent' if MacOsSystemLog::LOGGING_LEVELS.include?(log_type)
    return EVENT_TYPE_MAPPING[log_type.to_sym] if EVENT_TYPE_MAPPING.has_key?(log_type.to_sym)

    # Haven't actually seen these events in the syslog version of Apple's wilderness
    # but hopefully these regexes will capture them correctly.
    case log_type
    when /activ/i
      Rails.logger.warn("Ensure #{log_type} is not just Active")
      'activityTransitionEvent'
    when /sign/i
      'signpostEvent'
    when /trace/i
      'traceEvent'
    else
      Rails.logger.error("Unknown log type: #{log_type}!")
      nil
    end
  end

  def hex_to_int(hex_string)
    if hex_string.start_with?('0x')
      Integer(hex_string)
    else
      Rails.logger.warn("Bad hex string: #{hex_string}")
      nil
    end
  end
end
