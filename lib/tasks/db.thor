require 'fileutils'
require 'shellwords'
require 'thor'


class Db < Thor
  include Thor::Shell

  # Thor complains if this is not defined and there's an error
  def self.exit_on_failure?; end

  desc 'dump', "Write the database to a compressed archive via pg_dump."
  option :database,
          desc: 'Database to dump',
          default: ActiveRecord::Base.connection.current_database
  option :dir_to_dump_to,
          desc: 'Destination directory (default is configurable in .env)',
          default: ENV['DEFAULT_DB_DUMP_DIR'] || Rails.root.join('db', 'backups').to_s
  option :pg_dump_flags,
          default: '-Fc -Z9',
          desc: 'Flags for pg_dump. Default is max compression.'
  option :file_suffix,
          desc: 'Optional filename suffix for descriptive comments etc.'
  def dump
    dir_to_dump_to = options['dir_to_dump_to']
    database = options[:database]
    pg_dump_flags = options[:pg_dump_flags]

    filename = "#{database.delete_suffix("_#{Rails.env}")}_#{Time.now.strftime('%Y-%m-%dT%H%M%S%p')}"
    file_suffix = options[:file_suffix] || ask("Enter a descriptive suffix or hit enter if you don't want one:")
    filename += '_' + file_suffix unless file_suffix.blank?
    output_file = File.join(dir_to_dump_to, filename + '.pg_dump')

    unless Dir.exist?(dir_to_dump_to)
      say "\n#{dir_to_dump_to} does not exist!", :yellow
      yes?('Create?') ? FileUtils.mkdir_p(dir_to_dump_to) : exit
    end

    pg_dump_cmd = "pg_dump #{pg_dump_flags} -f #{output_file} #{database}"

    say "\nDatabase: "
    say database, :cyan
    say "Filename: "
    say filename, :cyan
    say "    Path: "
    say output_file, :cyan
    say "   Flags: "
    say pg_dump_flags, :cyan

    say "\n" + pg_dump_cmd, :bold
    exit unless yes?('Looks good? (y/n)')
    say 'Running...'
    system(pg_dump_cmd)
    say 'Complete.'
  end
end
