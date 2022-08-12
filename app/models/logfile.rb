# For old style log files, pre-unified logging

# TODO: log.0, log.1 etc. closed files

class Logfile < ApplicationRecord
  has_many :log_file_lines

  # TODO we could scan the disk?
  LOG_DIRS = [
    '/private/var/log/',
    '/Library/Logs',
    File.join(Dir.home, 'Library/Logs')
  ]

  ASL_EXTNAME = '.asl'  # Old logs format
  GZIP_EXTNAME = '.gz'
  BZIP2_EXTNAME = '.bz2'
  DIAGNOSTIC_EXTNAMES = %w(.diag .ips .core_analytics .shutdownStall .hang)
  ZIPPED_EXTNAMES = [GZIP_EXTNAME, BZIP2_EXTNAME]
  CLOSED_EXTNAMES = ZIPPED_EXTNAMES + DIAGNOSTIC_EXTNAMES

  def self.logfiles_on_disk
    logfile_paths_on_disk.map { |file| Logfile.new(file_path: file) }
  end

  def self.logfile_paths_on_disk
    LOG_DIRS.flat_map { |dir| Dir[File.join(dir, '**/*')] }.select { |f| File.file?(f) }
  end

  def self.closed_logfiles
    logfiles_on_disk.select { |logfile| logfile.closed? }
  end

  def self.open_logfiles
    logfiles_on_disk.select { |logfile| !logfile.closed? }
  end

  def self.print_list_of_logfiles(logfiles)
    puts "\n" + logfiles.map(&:file_path).sort.join("\n")
  end

  def self.create_from_file_path(file_path)
    new(file_path: file_path, file_created_at: File.ctime(file_path) )
  end

  # Store all at once
  def store_contents!
    self.file_contents = extract_contents
    self.save!
  end

  def extract_contents
    ShellCommandStreamer.new(streaming_shell_command).read
  end

  def extname
    File.extname(file_path)
  end

  def basename
    File.basename(file_path)
  end

  # zipped files are consider closed, as are .asl files that match a date other than today's
  def closed?
    return true if CLOSED_EXTNAMES.include?(extname)
    return true if extname =~ /^\.\d$/ && basename =~ (/log\.\d$/)
    return true if basename.start_with?('aslmanager')
    return true if file_path =~ /Homebrew\/.*post_install/
    return false unless extname == ASL_EXTNAME

    # ASL filenames look like '/private/var/log/asl/2022.08.09.G80.asl'
    if basename =~ /(\d{4}[.-]\d{2}[.-]\d{2}).*#{ASL_EXTNAME}/
      #puts "datematch #{basename}"
      $1.tr('.', '-').to_date < Date.today
    else
      #puts "NOT datematch #{basename}"
      false
    end
  end

  def open?
    !closed?
  end

  # Find the shell command that creates a stream
  def streaming_shell_command
    case File.extname(file_path)
    when BZIP2_EXTNAME
      'bzcat'
    when GZIP_EXTNAME
      'gunzip -c'
    when ASL_EXTNAME
      'syslog -f'
    else
      'cat'
    end + " \"#{file_path}\""
  end

  def print_to_terminal
    puts pastel.red("\n\n\n\n\n************* #{file_path} **************")
    puts pastel.yellow(self.extract_contents)
  end
end
