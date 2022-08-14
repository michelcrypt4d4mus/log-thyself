class FilterDefinitions
  PRNG = Random.new(2385)
  FILTER_DEFINITION_KEYS = %i[allowed? comment matchers]

  LOG_EVENT_FILTERS = [
    {
      comment: "This one plugin has spammed like 50GB of my hard drive. Improved by stopping coreaudiod but that's not a great long term solution",
      matchers: {
        sender_process_name: 'BTAudioHALPlugin',
        event_message: [
          'XPC server error: Connection invalid',
          'Invalidating all (0) audio devices',
          'Starting BTAudioPlugin for <private>',
          'Register audio plugin connection with bluetoothd'
        ]
      },
      allowed?: ->(event) { PRNG.rand(100) == 1 }
    },

    {
      comment: "Low level debug events",
      matchers: {
        process_name: [
          'corebrightnessd',
          'kernel',
          'powerd',
        ],
        message_type: 'Debug'
      },
      allowed?: ->(event) { false }
    },

    {
      comment: "Multitouch input to WindowServer",
      matchers: {
        process_name: 'WindowServer',
        sender_process_name: 'MultitouchHID',
        message_type: 'Debug'
      },
      allowed?: ->(event) { false }
    }
  ]

  def self.validate!
    LOG_EVENT_FILTERS.each do |filter|
      raise "Invalid filter:\n#{filter.pretty_inspect}" unless filter.keys.sort == FILTER_DEFINITION_KEYS

      filter[:matchers].each do |col, val|
        raise "Invalid matcher: #{col} is not a column" unless MacOsSystemLog.column_names.include?(col.to_s)
        raise "Invalid matcher for #{col}: #{val} is not a valid type " unless [Array, Numeric, String].include?(val.class)
      end

      unless [Proc, TrueClass, FalseClass].include?(filter[:allowed?].class)
        raise "Invalid rule for #{filter[:comment]}: :allowed? is not a Proc or bool"
      end
    end
  end
end
