# For old style log files, pre-unified logging

class Logfile < ApplicationRecord
  has_many :log_file_lines

  GZIP_EXTNAME = '.gz'
  BZIP2_EXTNAME = '.bz2'

  # Store all at once
  def store_contents!
    self.file_contents = extract_contents
    self.save!
  end

  def extract_contents
    ShellCommandStreamer.new(streaming_shell_command).read
  end

  def streaming_shell_command
    case File.extname(file_path)
    when BZIP2_EXTNAME
      "bzcat"
    when GZIP_EXTNAME
      "gunzip -c"
    else
      "cat"
    end + " \"#{file_path}\""
  end
end
