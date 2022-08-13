class LogfileLine < ApplicationRecord
  include PostgresCsvLoader

  belongs_to :logfile
  default_scope { order(:line_number) }

  UPSERT_KEYS = %i[logfile_id line_number]
end
