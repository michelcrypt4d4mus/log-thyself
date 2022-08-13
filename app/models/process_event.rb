class ProcessEvent < ApplicationRecord
  include ObjectiveSeeEvent

  JSON_PATHS = SHARED_JSON_PATHS.merge(process_path: PROCESS_PATH + '.path')
end
