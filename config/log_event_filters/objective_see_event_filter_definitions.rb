# Filters for FileEvent

class ObjectiveSeeEventFilterDefinitions < FilterDefinitions
  OPEN_AND_CLOSE = %w[NOTIFY_OPEN NOTIFY CLOSE]
  WRITE = 'NOTIFY_WRITE'

  IGNORED_RUBY_FILE_PATHS = %w[
    /Users/syblius/workspace/log-thyself/
    /Users/syblius/.rbenv/versions/3.1.2/
  ]

  FILE_EVENT_FILTERS = [
    {
      comment: 'Postgres and ProcessMonitor',  # https://developer.apple.com/forums/thread/701855
      matchers: {
        process_name: %w[
          postgres
          ProcessMonitor
        ],
      },
      allowed?: false
    },

    {
      comment: 'ruby libraries',
      matchers: {
        process_name: 'ruby',
        event_type: OPEN_AND_CLOSE,
        file: /#{Regexp.escape('/Users/syblius/.rbenv/versions/3.1.2/')}/
      },
      allowed?: false
    },

    {
      comment: 'ruby log/tty writing',
      matchers: {
        process_name: 'ruby',
        event_type: WRITE,
        file: /#{Regexp.escape('/Users/syblius/workspace/log-thyself/log/')}/
      },
      allowed?: false
    },

    {
      comment: 'log libraries',  # https://developer.apple.com/forums/thread/701855
      matchers: {
        process_name: 'log',
        event_type: OPEN_AND_CLOSE,
        file: /^\/System\//,
      },
      allowed?: false
    },
  ]

  PROCESS_EVENT_FILTERS = []
  FILTER_DEFINITIONS = PROCESS_EVENT_FILTERS + FILE_EVENT_FILTERS

  # Force logging of anything not meeting signing requirements
  # TDODO: Lookup known UUID before launch for stuff like ruby?
  FILTER_DEFINITIONS.each do |filter|
    filter[:matchers][:is_process_signed_as_reported] = true
  end

  def self.validate!
    validate_filter_definitions(PROCESS_EVENT_FILTERS, ProcessEvent.column_names)
    validate_filter_definitions(FILE_EVENT_FILTERS, FileEvent.column_names)
  end
end
