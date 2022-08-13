# For old style log files, pre-unified logging

class Logfile < ApplicationRecord
  has_many :log_file_lines

  after_initialize do |logfile|
    logfile.file_created_at ||= File.ctime(logfile.file_path)
  end

  # TODO we could scan the disk for logs?
  LIBRARY_LOGS = '/Library/Logs'
  VAR_LOG = '/private/var/log'

  LOG_DIRS = [
    VAR_LOG,
    LIBRARY_LOGS,
    File.join(Dir.home, LIBRARY_LOGS)
  ]

  # Extensions
  ASL_EXTNAME = '.asl'  # Old logs format
  GZIP_EXTNAME = '.gz'
  BZIP2_EXTNAME = '.bz2'
  DIAGNOSTIC_EXTNAMES = %w(.diag .ips .core_analytics .shutdownStall .hang)
  ZIPPED_EXTNAMES = [GZIP_EXTNAME, BZIP2_EXTNAME]
  CLOSED_EXTNAMES = ZIPPED_EXTNAMES + DIAGNOSTIC_EXTNAMES

  def self.logfile_paths_on_disk
    LOG_DIRS.flat_map { |dir| Dir[File.join(dir, '**/*')] }.select { |f| File.file?(f) }
  end

  def self.logfiles_on_disk
    logfile_paths_on_disk.map do |file_path|
      Logfile.where(file_path: file_path, file_created_at: File.ctime(file_path)).first_or_initialize
    end
  end

  def self.open_logfiles
    logfiles_on_disk.select(&:open?)
  end

  def self.closed_logfiles
    logfiles_on_disk.select(&:closed?)
  end

  def self.write_closed_logfile_contents_to_db!
    closed_logfiles.each { |logfile| puts logfile; logfile.write_contents_to_db! }
  end

  def stream_contents(&block)
    ShellCommandStreamer.new(streaming_shell_command).stream! { |line, line_number| yield(line, line_number) }
  end

  # Debug/utility method
  def self.print_list_of_logfiles(logfiles)
    puts "\n" + logfiles.map(&:file_path).sort.join("\n")
  end

  def write_contents_to_db!
    Rails.logger.info("Writing #{file_path} to DB")
    save!

    begin
      csv_string = CSV.generate(headers: LogfileLine.column_names - %w(id), write_headers: true, quote_char: '"') do |csv|
        stream_contents do |line, line_number|
          csv << LogfileLine.new(logfile_id: self.id, line_number: line_number, line: line).to_csv_hash(true)
        end
      end

      #Rails.logger.debug("CSV STRING:\n#{csv_string}\n\n")
      LogfileLine.load_from_csv_string(csv_string)
    rescue CSV::MalformedCSVError => e
      Rails.logger.error("Malformed CSV while processing '#{file_path}'")
      Rails.logger.error(e.message)
    end
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

    # ASL filenames look like '/private/var/log/asl/2022.08.09.G80.asl'
    if basename =~ /(\d{4}[.-]\d{2}[.-]\d{2})/
      $1.tr('.', '-').to_date < Date.today
    else
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
