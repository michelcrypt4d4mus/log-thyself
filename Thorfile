# /Thorfile

require File.expand_path("../config/environment", __FILE__)

require "thor"

THOR_TASKS_PATH = File.join(Rails.root, 'lib', 'tasks')
LOAD_ORDER = %w(collect db)

LOAD_ORDER.each do |thorfile|
  load(File.join(THOR_TASKS_PATH, "#{thorfile}.thor"))
end
