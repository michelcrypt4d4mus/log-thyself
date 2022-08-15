class FilterDefinitions
  PRNG = Random.new(2385)
  FILTER_DEFINITION_KEYS = %i[allowed? comment matchers]

  # Apple log levels
  (DEBUG, INFO, DEFAULT, ERROR, FAULT) = MacOsSystemLog::MESSAGE_TYPES

  # mds service low level
  MDS_MSG_PREFIXES = [
    "----",
    "NEXTQUEUE",
    "REORDER CHANGE",
    "EVAL",
    "handleXPCMessage",
    "Returning zero storeID",
    "REMOVE FROM HEAP",
    "ADD",
    "Leaving import restricted state",
    "=====",
    "Task <private> finished with status 0",
    "fetchItems at qos",
    "Truncating a list of bindings to",
    "Importer recycle"
  ]




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
        message_type: DEBUG
      },
      allowed?: false
    },

    {
      comment: "Multitouch / Universal control / SkyLight to WindowServer",
      matchers: {
        process_name: 'WindowServer',
        sender_process_name: [
          'ColourSensorFilterPlugin',
          'MultitouchHID',
          'SkyLight',
          'UniversalControlServiceFilter',
        ],
        message_type: DEBUG
      },
      allowed?: false
    },

    {
      comment: "Multitouch / Universal control / SkyLight to WindowServer",
      matchers: {
        process_name: 'WindowServer',
        sender_process_name: 'IOKit',
        message_type: DEBUG,
        event_message: /^0x[0-9A-Fa-f]{9}: set property/
      },
      allowed?: false
    },

    {
      comment: "GPU policy lookup",
      matchers: {
        sender_process_name: 'CoreFoundation',
        message_type: DEBUG,
        event_message: /^found no value for key gpu-policies in CFPrefsPlistSource/
      },
      allowed?: false
    },

    {
      comment: "_CSCheckFix",
      matchers: {
        sender_process_name: 'CarbonCore',
        category: 'checkfix',
        message_type: DEBUG
      },
      allowed?: false
    },

    {
      comment: 'com.apple.powerlog (power information logging system?)',
      matchers: {
        subsystem: 'com.apple.powerlog',
        message_type: DEBUG
      },
      allowed?: false
    },

    {
      comment: 'Low level display related debug events',
      matchers: {
        sender_process_name: 'IOHIDNXEventTranslatorSessionFilter',
        message_type: DEBUG,
        process_name: 'WindowServer'
      },
      allowed?: false
    },

    {
      comment: 'Signpost reporting (apple tech to allow app developers to time operations in their apps)',
      matchers: {
        process_name: 'signpost_reporter',
        message_type: [DEBUG, INFO]
      },
      allowed?: false
    },

    {
      comment: 'VS Code (Electron) HIToolbox',
      matchers: {
        process_name: 'Electron',
        message_type: DEBUG,
        subsystem: 'com.apple.HIToolbox'
      },
      allowed?: false
    },

    {
      comment: 'mds service spotlight low level',
      matchers: {
        process_name: 'mds',
        message_type: DEBUG,
        subsystem: 'com.apple.spotlightserver'
      },
      allowed?: false
    },

    {
      comment: 'mds launch services binding category',
      matchers: {
        process_name: 'mds',
        message_type: DEBUG,
        category: 'binding'
      },
      allowed?: false
    },

    {
      comment: 'Activity Monitor strings',
      matchers: {
        process_name: 'Activity Monitor',
        message_type: DEBUG,
        category: 'strings'
      },
      allowed?: false
    },

    {
      comment: 'BlockBlock allows',
      matchers: {
        process_name: 'BlockBlock',
        message_type: DEBUG,
        event_message: /^BlockBlock\.app\(\d+\): (allow|new process event: 0)/
      },
      allowed?: false
    },

    {
      comment: 'Little Snitch Agent gui stuff',
      matchers: {
        process_name: 'Little Snitch Agent',
        message_type: DEBUG,
        event_message: /^found no value for key (reduceTransparency|increaseContrast)/
      },
      allowed?: false
    },

    {
      comment: 'Little Snitch Icon Update',
      matchers: {
        process_name: 'Little Snitch Network Monitor',
        sender_process_name: 'IconServices',
        message_type: DEBUG,
      },
      allowed?: false
    },
  ]


  def self.validate!
    LOG_EVENT_FILTERS.each do |filter|
      raise "Invalid filter:\n#{filter.pretty_inspect}" unless filter.keys.sort == FILTER_DEFINITION_KEYS

      filter[:matchers].each do |col, val|
        raise "Invalid matcher: #{col} is not a column" unless MacOsSystemLog.column_names.include?(col.to_s)
        raise "Invalid matcher for #{col}: #{val} is not a valid type " unless [Array, Numeric, String, Regexp].include?(val.class)
      end

      unless [Proc, TrueClass, FalseClass].include?(filter[:allowed?].class)
        raise "Invalid rule for #{filter[:comment]}: :allowed? is not a Proc or bool"
      end
    end
  end
end
