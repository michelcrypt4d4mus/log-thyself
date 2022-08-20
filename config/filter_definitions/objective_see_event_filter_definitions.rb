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

    {
      comment: 'git libraries',
      matchers: {
        process_name: 'git',
        event_type: OPEN_AND_CLOSE,
        file: %w[
          /opt/homebrew/Cellar/pcre2/10.40/lib/libpcre2-8.0.dylib
          /opt/homebrew/Cellar/gettext/0.21/lib/libintl.8.dylib
          /Users/syblius/.gitconfig
          /Users/syblius/workspace/
          /opt/homebrew/.git
        ].map { |path| /^#{Regexp.escape(path)}/ },
      },
      allowed?: false
    },

    {
      comment: 'little snitch / VS code reads',
      matchers: {
        process_name: [
          'Little Snitch Software Update',
          'Code Helper (Renderer)',
          'rg',
          'Code',
          /^(Code|Code Helper|Code Helper \(Renderer\)|rg)$/
        ],
        event_type: OPEN_AND_CLOSE,
      },
      allowed?: false
    },

  # Force logging of anything not meeting signing requirements
  # TDODO: Lookup known UUID before launch for stuff like ruby?

  ]

  PROCESS_EVENT_FILTERS = []
  FILTER_DEFINITIONS = PROCESS_EVENT_FILTERS + FILE_EVENT_FILTERS

  # default to blacklist, force logging of anything not meeting signing requirements
  # TODO: Lookup known UUID before launch for stuff like ruby?
  FILTER_DEFINITIONS.each do |filter_def|
    filter_def[:matchers][:allowed?] = false unless filter_def[:matchers].has_key?(:allowed?)
    filter_def[:matchers][:is_process_signed_as_reported] = true
  end

  def self.validate!
    validate_filter_definitions(PROCESS_EVENT_FILTERS, ProcessEvent.column_names)
    validate_filter_definitions(FILE_EVENT_FILTERS, FileEvent.column_names)
  end
end
