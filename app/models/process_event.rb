# Objective-See ProcessMonitor event stream

class ProcessEvent < ApplicationRecord
  include ObjectiveSeeEvent
  include PostgresCsvLoader

  PREFERRED_BATCH_SIZE = 100
  PROCESS_PATH = '$.process'

  EVENT_TYPES = %w[
    NOTIFY_EXEC
    NOTIFY_EXIT
    NOTIFY_FORK
  ]

  JSON_PATHS = build_json_paths(PROCESS_PATH).merge(
    process_path: PROCESS_PATH + '.path',
    exit_code: PROCESS_PATH + ".'exit code'"
  )

  def self.json_paths
    JSON_PATHS
  end
end
