class LogfileLine < ApplicationRecord
  extend StyledNotifications
  include PostgresCsvLoader
  extend QueryStringHelper

  belongs_to :logfile
  default_scope { order(:line_number) }

  UPSERT_KEYS = %i[logfile_id line_number]
end
