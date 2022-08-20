# Extracts FileEvents from FileMonitor's JSON output and stores them along with the
# original JSON blob in case you want the other properties.

class FileEvent < ApplicationRecord
  include ObjectiveSeeEvent
  include PostgresCsvLoader

  EVENT_TYPES = ProcessEvent::EVENT_TYPES + %w[
     NOTIFY_CLOSE
     NOTIFY_CREATE
     NOTIFY_LINK
     NOTIFY_OPEN
     NOTIFY_RENAME
     NOTIFY_UNLINK
     NOTIFY_WRITE
  ]

  PREFERRED_BATCH_SIZE = 5000

  # JSON
  FILE_PATH = '$.file'
  PROCESS_PATH = FILE_PATH + '.process'
  JSON_PATHS = build_json_paths(PROCESS_PATH).merge(file: FILE_PATH + '.destination')

  def self.json_paths
    JSON_PATHS
  end
end
