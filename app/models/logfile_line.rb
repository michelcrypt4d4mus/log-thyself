class LogfileLine < ApplicationRecord
  include PostgresCsvLoader

  belongs_to :logfile
  default_scope { order(:line_number) }
end
