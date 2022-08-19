# For old style log files, pre-unified logging
require 'csv'


class Logfile < ApplicationRecord
  has_many :logfile_lines

  after_initialize do |logfile|
    logfile.file_created_at ||= File.ctime(logfile.file_path) unless Rails.env.test?
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
  PKLG_EXTNAME = '.pklg'  # packet logger, readable by wireshark etc.
  SYSLOG_SPECIAL_EXTNAME = '.the_system_logs'
  DIAGNOSTIC_EXTNAMES = %w[.core_analytics .diag .hang .ips .shutdownStall]
  ZIPPED_EXTNAMES = [GZIP_EXTNAME, BZIP2_EXTNAME]

  # pklg files aren't necessarily closed but it's annoying to parse them see https://superuser.com/questions/567831/follow-a-pcap-file-in-wireshark-like-tail-f
  # ASL files aren't necessarily closed but better to read them directly from syslog -w
  CLOSED_EXTNAMES = ZIPPED_EXTNAMES + DIAGNOSTIC_EXTNAMES + [PKLG_EXTNAME, ASL_EXTNAME]
  ALL_EXTNAMES = CLOSED_EXTNAMES + %w[.info .log .out .python3 .txt]

  # Shell commands
  TAIL_FROM_TOP = 'tail -c +0'
  TAIL_FROM_TOP_STREAMING = TAIL_FROM_TOP + ' -F'
  SYSLOG_READ_CMD = 'syslog -F raw -T utc.6'

  # Batch size to use for bulk loads
  BULK_LOAD_BATCH_SIZE = 10_000
  IGNORE_ERRORS_ON_FILES_OF_LENGTH_LESS_THAN = 100 ## characters

  def self.logfile_paths_on_disk
    LOG_DIRS.flat_map { |dir| Dir[File.join(dir, '**/*')] }.select { |f| File.file?(f) }
  end

  def self.logfiles_on_disk
    logfile_paths_on_disk.map do |file_path|
      Logfile.where(file_path: file_path, file_created_at: File.ctime(file_path)).first_or_initialize
    end
  end

  def self.open_logfiles
    logfiles_on_disk.select(&:open?) + [synthetic_syslog_file]
  end

  def self.closed_logfiles
    logfiles_on_disk.select(&:closed?)
  end

  # Collects all extant logfiles that we think will no longer be written to
  def self.write_closed_logfile_contents_to_db!
    closed_logfiles.each { |logfile| logfile.write_contents_to_db! }
  end

  def self.load_all_files_in_directory!(dir, options = {})
    raise "Directory '#{dir}' doesn't exist" unless Dir.exist?(dir)
    include_subdirs = options[:include_subdirs].blank? ? true : options[:include_subdirs]

    Dir[File.join(dir, (include_subdirs ? '**/*' : '*'))].each do |file_path|
      next unless File.file?(file_path)
      logfile = Logfile.where(file_path: file_path, file_created_at: File.ctime(file_path)).first_or_create!

      begin
        logfile.write_contents_to_db!
      rescue StandardError => e
        msg = "#{e.class.to_s} while processing #{file_path}, will write the error info instead to #{LogfileLine.table_name}. "
        msg += "Error Message: #{e.message}"
        puts msg
        msg += "\nBacktrace:\n#{e.backtrace.join("\n")}"
        Rails.logger.error(msg)
      end
    end
  end

  # Debug/utility method
  def self.print_list_of_logfiles(logfiles)
    puts "\n" + logfiles.map(&:file_path).sort.join("\n")
  end

  # Syslog is not really a file, but we make a Logfile that looks like it is.
  def self.synthetic_syslog_file
    new(
      file_path: "syslog_#{Time.now.utc.strftime('%Y-%m-%dT%H%M%S%p')}#{SYSLOG_SPECIAL_EXTNAME}",
      file_created_at: Time.now.utc
    )
  end

  # Stream a file line by line
  def stream_contents(&block)
    ShellCommandStreamer.new(shell_command_to_read).stream! do |line, line_number|
      yield(line, line_number)
    end
  end

  # Writes entire file to log_lines table as separate lines.
  # Returns lines written count.
  def write_contents_to_db!
    save!
    Rails.logger.info("Loading '#{file_path}' to DB")
    return 0 if extname == SYSLOG_SPECIAL_EXTNAME

    begin
      lines_written = CsvDbWriter.open(LogfileLine, batch_size: BULK_LOAD_BATCH_SIZE) do |db_writer|
        stream_contents do |line, line_number|
          line = line.gsub("\u0000", '').force_encoding(Encoding::UTF_8)
          db_writer << LogfileLine.new(logfile_id: self.id, line_number: line_number, line: line)
        end
      end
    rescue CSV::MalformedCSVError => e
      # Ignore CSV errors for small files
      (line_count, word_count, byte_count, _) = `wc #{file_path}`.split
      Rails.logger.error("#{e.class.to_s} loading '#{file_path}' to DB.")
      raise e if byte_count > IGNORE_ERRORS_ON_FILES_OF_LENGTH_LESS_THAN

      msg = "#{e.class.to_s}: #{e.message} but file is short (#{line_count} lines / #{byte_count} bytes) so moving on..."
      say_and_log(msg, log_level: :warn, styles: [:yellow])
      lines_written = number_of_logfile_lines
    end

    if lines_written != number_of_logfile_lines
      Rails.logger.warn("ID #{id}. '#{file_path}' claims #{lines_written} but #{number_of_logfile_lines} in DB!")
    else
      Rails.logger.info("Loaded #{lines_written} rows of #{file_path} via CSV")
    end

    lines_written
  end

  def extract_contents
    ShellCommandStreamer.new(shell_command_to_read).read
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
    return true if ['alf.log', 'daily.out'].include?(basename) # Never anything in here / only once a day
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

  # TODO: this belongs on the streamer classes
  # Find the shell command that can read the file
  def shell_command_to_read(include_path: true)
    case File.extname(file_path)
    when BZIP2_EXTNAME
      'bzcat'
    when GZIP_EXTNAME
      'gunzip -c'
    when ASL_EXTNAME
      # syslog -f only prints the last few lins unless we do the 'cat' pipe to STDIN
      return "cat \"#{file_path}\" | #{SYSLOG_READ_CMD} -f"
    when PKLG_EXTNAME
      if system('which tshark')
        'tshark -r'
      else
        msg = 'tshark could not be found to parse the file. install it if you want the bluetooth .pklg files parsed.'
        Rails.logger.warn(msg)
        "echo -e \"#{msg}\""
      end
    when SYSLOG_SPECIAL_EXTNAME
      return "#{SYSLOG_READ_CMD} -B"  # -B is 'from last boot'
    else
      'cat'
    end + (include_path ? " \"#{file_path}\"" : '')
  end

  def shell_command_to_stream
    cmd = shell_command_to_read(include_path: false)

    case cmd
    when 'cat'
      "#{TAIL_FROM_TOP_STREAMING} \"#{file_path}\""
    when /syslog/
      if extname == SYSLOG_SPECIAL_EXTNAME
        "#{SYSLOG_READ_CMD} -w all"
      else
        Rails.logger.warn('syslog -w FILE does not stream from a file even though docs say it should')
        nil
      end
    when /tshark/
      raise 'tail -f causes issues with tshark, sadly'
    else
      "#{TAIL_FROM_TOP_STREAMING} \"#{file_path}\" | #{cmd}"
    end
  end

  def number_of_logfile_lines
    self.logfile_lines.count
  end

  def print_to_terminal
    puts pastel.red("\n\n\n\n\n************* #{file_path} **************")
    puts pastel.yellow(self.extract_contents)
  end
end
