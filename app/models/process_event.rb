# Objective-See ProcessMonitor event stream

class ProcessEvent < ApplicationRecord
  include ObjectiveSeeEvent
  include PostgresCsvLoader

  PROCESS_PATH = '$.process'

  JSON_PATHS = build_json_paths(PROCESS_PATH).merge(
    process_path: PROCESS_PATH + '.path',
    exit_code: PROCESS_PATH + ".'exit code'"
  )

  def self.json_paths
    JSON_PATHS
  end
end
