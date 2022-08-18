# /Thorfile

require 'dotenv'
require 'pastel'
#Dotenv.load(File.join(Rails.root, '.env'))


require File.expand_path("../config/environment", __FILE__)
require "thor"

THOR_TASKS_PATH = File.join(Rails.root, 'lib', 'tasks')
LOAD_ORDER = %w(collect db)

puts "\n"

LOAD_ORDER.each do |thorfile|
  load(File.join(THOR_TASKS_PATH, "#{thorfile}.thor"))
end


WARNING_BANNER = '🚨 '

unless Rails.env.production?
  pastel = Pastel.new

  msg = WARNING_BANNER + pastel.bold.bright_red.inverse(" WARNING: You are not running in the proper environment to connect to the database. ")
  puts msg + ' ' + WARNING_BANNER + "\n\n"
  msg = pastel.bright_red("This won't affect installation or running as a daemon, but to run manually you have two options:\n")
  msg += pastel.bright_red("     1. prepend RAILS_ENV=production to your commands. Example: ")
  msg += pastel.cyan("RAILS_ENV=production thor collect:syslog:stream\n")
  msg += pastel.bright_red("     2. permanently set RAILS_ENV by running this in Terminal: ")
  msg += pastel.cyan(" echo -e \"\\nRAILS_ENV=production\\n\" >> ~/.bash_profile\n\n")
  puts msg
end
