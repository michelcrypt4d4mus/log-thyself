class LogfileLine < ApplicationRecord
  belongs_to :logfile
  default_scope { order(:line_number) }
end
