# Watches logs from the old file system
# Re: tail args
#   -F handles log rotations with grace.
#   -50000000 should guarantee us the whole file.

require 'tty'

class LogFileWatcher
  attr_accessor :streamer_threads

  def load_and_stream!
    @streamer_threads = Logfile.open_logfiles.inject({}) do |memo, logfile|
      logfile.save!

      memo[logfile] = Thread.new do
        ShellCommandStreamer.new(logfile.shell_command_to_stream).stream! do |line, line_number|
          line = line.gsub("\u0000", '').force_encoding(Encoding::UTF_8)  # Null byte...
          LogfileLine.where(logfile_id: logfile.id, line_number: line_number, line: line).first_or_create!
        end
      end

      memo
    end

    tty_table_data_old = []

    while(true) do
      sleep(5)
      tty_table_header = ['logfile path', 'alive?', 'max line number']

      tty_table_data = @streamer_threads.inject([]) do |table, (logfile, thread)|
        table << [logfile.basename, thread.alive?, logfile.logfile_lines.size]
      end

      tty_table_data.sort_by!(&:to_s)

      if tty_table_data != tty_table_data_old
        puts "**** STATUS CHANGE ****"
      end

      tty_table_data_old = tty_table_data
      table = TTY::Table.new(header: tty_table_header, rows: tty_table_data)
      puts TTY::Table::Renderer::Basic.new(table).render
      puts "\n\n\n"
    end
  end
end
