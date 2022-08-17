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
  "Importer recycle",
  # mds_stores
  'Dummy for oid'
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
  ShowUnmatchedMenuBounds
  cursorIsCustomized
  MouseCopyPasteUsesClipboard
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
      comment: "corebrightnessd",
      matchers: {
        process_name: 'corebrightnessd',
        message_type: [DEFAULT, INFO],
        event_message: [
          /^ramps (clocked|updated)/
        ]
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
      comment: 'com.apple.WebKit.WebContent etc',
      matchers: {
        sender_process_name: [
          'CoreServicesStore',
          'JavaScriptCore',
          'ExtensionFoundation',
          'WebCore',
        ],
        message_type: INFO_OR_LESS,
        event_message: [
          /^(Current memory footprint|Enumerator returnin|New length of store is|Attempting to lengthen store)/,
          /^(backforward_cache_page_count|document_count|page_count|javascript_gc_heap)/
        ]
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
        message_type: INFO_OR_LESS,
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
        process_name: [
          'mds',
          'mds_stores',
        ],
        message_type: DEBUG,
        subsystem: /com\.apple\.spotlight(server|index)/
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
      comment: 'distnoted unregister token',
      matchers: {
        process_name: 'distnoted',
        event_message: [
          event_message: /^unregister token: /,
        ],
        message_type: DEFAULT
      },
      allowed?: false
    },

    {
      comment: 'SymptomEvaluator cannot handle ethernet',
      matchers: {
        process_name: 'symptomsd',
        event_message: [
          "Don't have a tracker for WiredEthernet interface type",
          /^(processExtendedUpdate|Dynamic lookup for|found LU hint|Conn createSnapshot|Flow report)/,
          /__SCNetworkReachabilityGetFlagsFromPath/,
        ]
      },
      allowed?: false
    },

    {
      comment: 'Malware Bytes',
      matchers: {
        process_name: 'RTProtectionDaemon',
        message_type: 'Debug'
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
      comment: 'locationd',
      matchers: {
        process_name: 'locationd',
        message_type: DEBUG,
        event_message: [
          'Ping timer fired, resetting watchdog',
          /^{"msg":"/  # sqlite?
        ]
      },
      allowed?: false
    },

    {
      comment: 'IconServices debug/info level',
      matchers: {
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
          /^(Uncached value for|Duet: ClientContext objectForContextualKeyPath)/
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
          /^(Stats Report|===)/,
          /^(Stats toggle|  filling \d+ attributes for type|NET \| Request|After reading settings|found a referenced key)/,
          'SecTrustReportNetworkingAnalytics',
          'Activity for state dumps',
          'CSPDL FreeKey',
        ]
      },
      allowed?: false
    },


    {
      # Keep the new session debug events!
      comment: 'boringSSL',
      matchers: {
        sender_process_name: 'libboringssl.dylib',
        message_type: INFO_OR_LESS,
        event_message: [
          /^(nw_protocol_boringssl_read_byt|boringssl_bio_destroy|boring_ssl_context_log_message)/
        ]
      },
      allowed?: false
    },

    {
      comment: 'libnetworkextension.dylib debug events',
      matchers: {
        sender_process_name: [
          'libnetworkextension.dylib',
          'libnetwork.dylib'
        ],
        message_type: INFO_OR_LESS,
        event_message: [
          # libnetworkextension
          /^(SIGN \w+: |\[filter [A-F0-9]{8}|FILTER |Stats toggle|NEHelperTrackerGetDisposition)/,
          # libnetwork
          /^(After settings override|Final domain cfnetwork)/,
          /^(Returning should log|Not checking if we should log for|No threshold for cfnetwor|Domain cfnetwork rate)/,
          /^(nw|sa)_\w+/,  # lots of low level calls
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
          /^Fire delay: /,
          /^(BEGIN|END) suppressing state updates/,
          /Decrementing suppression state to/

        ],
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
      comment: 'launchservices low level communications',
      matchers: {
        process_name: 'launchservicesd',
        category: 'cas',
        message_type: INFO_OR_LESS,
        event_message: [
          /^MESSAGE: reply={result={CFBundleIdentifier="(#{LAUNCHD_COMMS_IGNORE_BUNDLE_IDS.join('|')})"/,
          /^MESSAGE: reply={result={LSBundlePath="(#{LAUNCHD_COMMS_IGNORE_BUNDLE_PATHS.join('|')})/,
          /Need to lookup or create kLSDefaultSessionID for client\.$/,
          'assertionsDidInvalidate',
          /^(SETFRONT|void LSNotification|Moving App:|Returning session|static Boolean LSNotification|-- using cached connection|Acquiring assertion:)/
        ]
      },
      allowed?: false
    },

    {
      comment: 'LaunchServices low level communications',
      matchers: {
        sender_process_name: 'LaunchServices',
        category: 'cas',
        message_type: INFO_OR_LESS,
        event_message: [
          /^(applicationInformationSeed|Invoking selector|Truncating a list of binding|Creating binding evaluator)/,
          /^key="(LSExpectedFrontApplicationASNKey|UIPresentationMode|LSFrontReservationExists|LSPermittedFrontASNs|CFDictionaryRef|No weak binding found)"/,
          /^\d+ bindings found$/,
          /^Destroying binding evaluator 0x[0-9A-Fa-f]+$/,
          /^(LS\/CAS: Changed front application|CopyFrontApplication|Getting plist hint for data)/,
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
          /^(64-bit linkedit is valid|SecTrustEvaluateIfNecessary)$/,
          /^Skipping [-\w\s]+ due to options/
        ],
      },
      allowed?: false
    },

    {
      comment: 'Security',
      matchers: {
        sender_process_name: 'Security',
        event_message: [
          /^0x[0-9A-Fa-f]+ validating slot -\d+$/,
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
        event_message: /^(found no value for key|looked up value)/
      },
      allowed?: ->(event) { (event[:process_name] || '') == 'Terminal' }  # Terminal has its own rows
    },

    {
      comment: 'CoreAnalytics',
      matchers: {
        sender_process_name: 'CoreAnalytics',
        message_type: DEFAULT_OR_LESS,
        event_message: [
          /^Dropping [\w.><]+ as it isn't used in any transform/,
          /^com\.apple\.power\.battery/,
          /^(Enter|Exit)ing exit handler\.$/,
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
    },

    {
      comment: "debug 'strings' category (looks like a bunch of printf formatting arguments)",
      matchers: {
        category: 'strings',
        message_type: DEBUG,
      },
      allowed?: false
    },

    {
      comment: "com.apple.Safari.SearchHelper",
      matchers: {
        process_name: 'com.apple.Safari.SearchHelper',
        message_type: INFO_OR_LESS,
      },
      allowed?: false
    },

    {
      comment: "com.apple.Safari.SearchHelper",
      matchers: {
        process_name: 'Safari',
        category: 'ThemeColor'
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
