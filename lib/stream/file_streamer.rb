# Subclass of ShellCommandStreamer. Turns various kinds of files into line by line streams

class FileStreamer < ShellCommandStreamer
  include StyledNotifications

  # Shell commands
  TAIL_FROM_TOP = 'tail -c +0'
  TAIL_FROM_TOP_STREAMING = TAIL_FROM_TOP + ' -F'
  SYSLOG_READ_CMD = 'syslog -F raw -T utc.6'

  def initialize(file_path, live_stream: false)
    @file_path = file_path
    super((live_stream ? shell_command_to_stream : shell_command_to_read))
  end

  # Find the shell command that can read the file
  # TODO: include_path optional arg is serious code smell
  def shell_command_to_read(include_path: true)
    case file_extname
    when Logfile::BZIP2_EXTNAME
      'bzcat'
    when Logfile::GZIP_EXTNAME
      'gunzip -c'
    when Logfile::ASL_EXTNAME
      # syslog -f only prints the last few lines unless we do the 'cat' pipe to STDIN
      return "cat \"#{@file_path}\" | #{SYSLOG_READ_CMD} -f"
    when Logfile::PKLG_EXTNAME
      if `which tshark`.present?
        'tshark -r'
      else
        msg = 'tshark could not be found to parse the file. install it if you want the bluetooth .pklg files parsed.'
        say_and_log(msg, log_level: :error)
        return "echo -e \"#{msg}\""
      end
    when Logfile::SYSLOG_SPECIAL_EXTNAME
      return "#{SYSLOG_READ_CMD} -B"  # -B is 'from last boot'
    else
      'cat'
    end + (include_path ? " \"#{@file_path}\"" : '')
  end

  def shell_command_to_stream
    cmd = shell_command_to_read(include_path: false)

    case cmd
    when 'cat'
      "#{TAIL_FROM_TOP_STREAMING} \"#{@file_path}\""
    when /syslog/
      raise 'syslog -w FILE does not stream' unless file_extname == Logfile::SYSLOG_SPECIAL_EXTNAME
      "#{SYSLOG_READ_CMD} -w all"
    when /tshark/
      raise 'tail -f causes issues with tshark, sadly'
    else
      "#{TAIL_FROM_TOP_STREAMING} \"#{@file_path}\" | #{cmd}"
    end
  end

  private

  def file_extname
    File.extname(@file_path)
  end
end
