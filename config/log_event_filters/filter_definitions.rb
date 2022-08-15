LAUNCHD_COMMS_IGNORE_BUNDLE_IDS = %w[
  at.obdev.littlesnitch.networkmonitor
  at.obdev.littlesnitch.agent
  com.apple.appkit.xpc.openAndSavePanelService
  com.apple.dock.extra
  com.apple.finder
  com.apple.Safari
  com.apple.UnmountAssistantAgent
  com.apple.WebKit.WebContent
  com.microsoft.VSCode
].map { |id| Regexp.escape(id) }

LAUNCHD_COMMS_IGNORE_BUNDLE_PATHS_HEREDOC = <<-PATH
/Applications/Safari.app
/System/Library/Frameworks/WebKit.framework/Versions/A/XPCServices/com.apple.WebKit.WebContent.xpc
/System/Library/Frameworks/AppKit.framework/Versions/C/XPCServices/com.apple.appkit.xpc.openAndSavePanelService.xpc
/System/Library/CoreServices/Dock.app/Contents/XPCServices/com.apple.dock.extra.xpc
/Applications/Little Snitch.app/Contents/Components/Little Snitch Network Monitor.app
/Applications/Little Snitch.app/Contents/Components/Little Snitch Agent.app
/Applications/Visual Studio Code.app
/System/Library/CoreServices/Finder.app
/System/Library/CoreServices/loginwindow.app
PATH

LAUNCHD_COMMS_IGNORE_BUNDLE_PATHS = LAUNCHD_COMMS_IGNORE_BUNDLE_PATHS_HEREDOC.split("\n").map { |path| Regexp.escape(path.strip) }

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

TERMINAL_DEBUG_SPAM = %w[
  WindowBorderMinBrightness
  Command1Through9SwitchesTabs
  AutoMarkPromptLines
  ShowLineMarks
  UseAppIBeamCursor
  WindowBorderMaxSaturation
  NewWindowSettingsBehavior
  ShouldLimitRestoreScrollback
  NewTabSettingsBehavior
  NSWindow
  NSWindow
  TTWindowActivationDuration
  AppleLanguages
  AssignWindowShortcutsToTabbedWindows
  FocusFollowsMouse
  FocusFollowsMouseInBackground
  NSServicesStatus
  NSWindow
  ShowTabBar
  ShowTabBarInFullScreen
  TTWindowDeactivationDuration
  NewWindowWorkingDirectoryBehavior
  NewTabWorkingDirectoryBehavior
]

class FilterDefinitions
  PRNG = Random.new(2385)
  FILTER_DEFINITION_KEYS = %i[allowed? comment matchers]

  # Apple log levels
  (DEBUG, INFO, DEFAULT, ERROR, FAULT) = MacOsSystemLog::MESSAGE_TYPES
  INFO_OR_LESS = [INFO, DEBUG]
  DEFAULT_OR_LESS = [DEFAULT] + INFO_OR_LESS

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
      comment: "WindowServer Status bar is going to clip a never-clip item",
      matchers: {
        process_name: 'WindowServer',
        event_message: /^Status bar is going to clip a never-clip item/,
        message_type: ERROR
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
        subsystem: %w[
          com.apple.CFBundle
          com.apple.CFPasteboard
          com.apple.defaults
          com.apple.HIToolbox
        ]
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
      comment: 'Activity Monitor SafeEjectGPU',
      matchers: {
        process_name: 'Activity Monitor',
        sender_process_name: 'SafeEjectGPU',
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
      comment: 'SymptomEvaluator cannot handle ethernet',
      matchers: {
        process_name: 'symptomsd',
        event_message: "Don't have a tracker for WiredEthernet interface type"
      },
      allowed?: false
    },

    {
      comment: 'reduceTransparency, increaseContrast',
      matchers: {
        message_type: DEBUG,
        event_message: /^found no value for key (reduceTransparency|increaseContrast)/
      },
      allowed?: false
    },

    {
      comment: 'thermalmonitord, kernel',
      matchers: {
        process_name: %w[
          kernel
          thermalmonitord
        ],
        message_type: DEFAULT_OR_LESS,
        event_message: [
          /^iterated \d+ channels with \d+ iterations/,  # thermalmonitord
          # Kernel
          /^ApplePPMPolicyCPMS::setDetailedThermalPowerBudget:setDetailedThermalPowerBudget/,
          /^(postMessageInternal:isPipeOpened|cfil_acquire_sockbuf|memorystatus: set assertion priority|apfs_snap_vnop_create)/,
        ]
      },
      allowed?: false
    },

    # PAH = "press and hold"
    {
      comment: 'reduceTransparency, increaseContrast',
      matchers: {
        process_name: 'PAH_Extension',
        event_message: [
          'Get bundle identifier',
          'Get window level',
          /^(-windowLevel produced \d+|sessionFinished)/,
          /^(De)*activate ?Server/i
        ]
      },
      allowed?: false
    },

    {
      comment: 'FreeUniqueRecord from Security dbsession',
      matchers: {
        message_type: DEBUG,
        category: 'dbsession',
        event_message: [
          /^FreeUniqueRecord: [0-9A-Za-f]+$/,
          /^DataGetNext\([0-9a-z]+\)/
        ]
      },
      allowed?: false
    },

    {
      comment: 'securityd',
      matchers: {
        process_name: 'securityd',
        message_type: DEBUG,
        event_message: [
          /^Empty (start|end) date$/,
          'request return: 0',
          'end request',
          /^(---|===) BlockCryptor/,
          /^begin request: \d+, \d+$/
        ]
      },
      allowed?: false
    },

    {
      comment: 'Little Snitch Icon Update',
      matchers: {
        process_name: 'Little Snitch Network Monitor',
        sender_process_name: 'IconServices',
        message_type: INFO_OR_LESS,
      },
      allowed?: false
    },

    {
      comment: 'dasd',
      matchers: {
        process_name: 'dasd',
        message_type: DEFAULT_OR_LESS,
        event_message: [
          /^(com.apple.dasd.default: Current Load=|Current load for group|Attempting to suspend|Evaluating \d+ activities based on triggers)/,
        ]
      },
      allowed?: false
    },


    {
      comment: 'at.obdev.littlesnitch.networkextension',
      matchers: {
        process_name: 'at.obdev.littlesnitch.networkextension',
        message_type: DEBUG,
        event_message: /^(Socket Stats Report|Channel Stats Report|Fetching appInfo from cache for pid)/
      },
      allowed?: false
    },

    {
      comment: 'ProtonVPN low level',
      matchers: {
        process_name: 'ProtonVPN',
        message_type: DEBUG,
        event_message: [
          /^0x[0-9A-Fa-f]+ Data(GetFromUniqueId|First|AbortQuery)/,
          /^(Returning should log|Stats Report|No threshold for cfnetwor|===|\[filter [A-F0-9{8}])/,
          /^(SIGN |Stats toggle|  filling \d+ attributes for type|NET \| Request|Domain cfnetwork rate|After reading settings|found a referenced key)/,
          'SecTrustReportNetworkingAnalytics',
          'Activity for state dumps',
          'CSPDL FreeKey',
        ]
      },
      allowed?: false
    },


    {
      comment: 'runningboardd state update',
      matchers: {
        process_name: 'runningboardd',
        event_message: [
          'acquireAssertionWithDescriptor',
          'invalidateAssertionWithIdentifier',
          'Processing events',
          'state notification',
          'state update',
          'end request',
        ]
      },
      allowed?: false
    },

    {
      comment: 'runningboardd assertions',
      matchers: {
        process_name: 'runningboardd',
        category: 'assertion'
      },
      allowed?: false
    },

    {
      comment: 'runningboardd spam',
      matchers: {
        process_name: 'runningboardd',
        event_message: [
          /Ignoring (GPU|jetsam|suspend|role|CPU) ((update|limits|changes) )?because this process is not (GPU|memory-|lifecycle|role|CPU limit) ?managed$/,
          /^Ignoring insignificant state update/,
          /Applying updated state$/,
          'timer'
        ]
      },
      allowed?: false
    },

    {
      comment: 'launchservices basic communications',
      matchers: {
        process_name: 'launchservicesd',
        category: 'cas',
        message_type: INFO_OR_LESS,
        event_message: [
          /^MESSAGE: reply={result={CFBundleIdentifier="(#{LAUNCHD_COMMS_IGNORE_BUNDLE_IDS.join('|')})"/,
          /^MESSAGE: reply={result={LSBundlePath="(#{LAUNCHD_COMMS_IGNORE_BUNDLE_PATHS.join('|')})/,
          /Need to lookup or create kLSDefaultSessionID for client\.$/
        ]
      },
      allowed?: false
    },

    {
      comment: 'opendirectoryd pipeline',
      matchers: {
        process_name: 'opendirectoryd',
        category: 'pipeline',
        event_message: 'submitting request to internal pipeline',
        message_type: DEBUG
      },
      allowed?: false
    },

    {
      comment: 'tccd',
      matchers: {
        process_name: 'tccd',
        event_message: [
          /^0x[0-9A-Fa-f]+ validating slot -\d+$/,
          /^Destroying binding evaluator 0x[0-9A-Fa-f]+$/,
          /^(64-bit linkedit is valid|SecTrustEvaluateIfNecessary)$/,
          /^Skipping [-\w\s]+ due to options/
        ],
      },
      allowed?: false
    },

    {
      comment: 'staticCode low level messages',
      matchers: {
        category: 'staticCode',
        event_message: [
          /^0x[0-9A-Fa-f]+ (creating new CEQueryContext|loaded) DER blob with length \d+$/,
          /^0x[0-9A-Fa-f]+ (loaded InfoDict|xml size)/,
          /^SecStaticCode network (allowed|default): NO$/,
        ],
      },
      allowed?: false
    },

    {
      comment: 'opendirectoryd low level debug',
      matchers: {
        process_name: 'opendirectoryd',
        category: 'object-lifetime',
        message_type: DEBUG
      },
      allowed?: false
    },

    {
      comment: 'All processes user defaults lookups',
      matchers: {
        category: 'User Defaults',
        message_type: DEBUG,
        event_message: /^found no value for key/
      },
      allowed?: false
    },

    {
      comment: 'CoreAnalytics',
      matchers: {
        sender_process_name: 'CoreAnalytics',
        message_type: INFO_OR_LESS,
        event_message: [
          /^Dropping [\w.><]+ as it isn't used in any transform/,
          /^com\.apple\.power\.battery/,
          /^(Enter|Exit)ing exit handler\.$/
        ]
      },
      allowed?: false
    },

    {
      comment: 'Biome metrics',
      matchers: {
        subsystem: 'com.apple.Biome',
        message_type: INFO_OR_LESS,
        event_message: [
          /^(Metric not in use: |Frame store |BMComputeSourceServerConnection send event|Logging CoreAnalytics donation |)/,
        ]
      },
      allowed?: false
    },

    {
      comment: 'Terminal spam events',
      matchers: {
        process_name: 'Terminal',
        category: 'User Defaults',
        message_type: DEBUG,
        event_message: /^looked up value [\w<>]+ for key (#{TERMINAL_DEBUG_SPAM.join('|')}) in/,
      },
      allowed?: false
    },

    {
      comment: 'Terminal clipboard events',
      matchers: {
        process_name: 'Terminal',
        subsystem: 'com.apple.CFPasteboard',
        message_type: INFO_OR_LESS,
        event_message: [
          /^(result: 0$|Successfully (promised|set) data \((new-entry|cache)\)|PromiseDataUsingBlock|Flushing \d+ pending entries synchronously for pboard|#cache-invalidation|BeginGeneration\('(com.apple.Terminal.selection|Apple CFPasteboard general)')/,
          /com\.apple\.pboard\.invalidate-cache$/
        ]
      },
      allowed?: false
    }
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
