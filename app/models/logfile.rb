# For old style log files, pre-unified logging

# TODO: log.0, log.1 etc. closed files

class Logfile < ApplicationRecord
  has_many :log_file_lines

  ASL_EXTNAME = '.asl'  # Old logs format
  GZIP_EXTNAME = '.gz'
  BZIP2_EXTNAME = '.bz2'
  ZIPPED_EXTNAMES = [GZIP_EXTNAME, BZIP2_EXTNAME]
  DIAG_EXTNAMES = %w(.diag .ips .core_analytics .shutdownStall .hang)
  CLOSED_EXTNAMES = ZIPPED_EXTNAMES + DIAG_EXTNAMES

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
    return true unless extname != ASL_EXTNAME

    # ASL filenames look like '/private/var/log/asl/2022.08.09.G80.asl'
    if basename =~ /(\d{4}[.-]\d{2}[.-]\d{2}).*#{ASL_EXTNAME}/
      $1.tr('.', '-').to_date < Date.today
    else
      false
    end
  end

  # Find the shell command that creates a stream
  def streaming_shell_command
    case File.extname(file_path)
    when BZIP2_EXTNAME
      'bzcat'
    when GZIP_EXTNAME
      'gunzip -c'
    WHEN ASL_EXTNAME
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
