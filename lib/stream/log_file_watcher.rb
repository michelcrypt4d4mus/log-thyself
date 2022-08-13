# Watches logs from the old file system
# Re: tail args
#   -F handles log rotations with grace.
#   -50000000 should guarantee us the whole file.

require 'pastel'
require 'tty'

class LogFileWatcher
  class << self
    attr_accessor :streamer_threads
  end

  def self.load_and_stream_all_open_logfiles!
    @streamer_threads = Logfile.open_logfiles.inject({}) do |memo, logfile|
      memo[logfile] = new(logfile).load_and_stream!
      memo
    end

    tty_table_data_old = []
    pastel = Pastel.new

    while(true) do
      tty_table_header = ['id', 'logfile path', 'alive?', 'CSV lines', 'Extra Lines']

      tty_table_data = @streamer_threads.inject([]) do |table, (logfile, hsh)|
        table << [
          logfile.id,
          logfile.file_path.strip,
          hsh[:thread].alive? ? 'alive' : 'DEAD',
          hsh[:csv_lines] || 0,
          logfile.logfile_lines.size - (hsh[:csv_lines] || 0)
        ]
      end

      tty_table_data.sort_by! { |row| File.basename(row[1]) }

      if tty_table_data != tty_table_data_old
        puts "**** STATUS CHANGE ****"
      end

      tty_table_data_old = tty_table_data
      table = TTY::Table.new(header: tty_table_header, rows: tty_table_data)

      puts TTY::Table::Renderer::Unicode.new(table).render
      puts "\n\n\n"
      sleep(5)
    end
  end

  def initialize(logfile)
    logfile.save!
    @logfile = logfile
    @info = {}
  end

  # Returns a hash with the thread that was spawned and the lines loaded by initial CSV
  def load_and_stream!
    @info[:csv_lines] = @logfile.write_contents_to_db!
    initial_lines_in_db = @logfile.logfile_lines.count

    if @info[:csv_lines] != initial_lines_in_db
      if @info[:csv_lines] == 1 && initial_lines_in_db == 0
        @info[:csv_lines] = 0
      else
        puts "WARNING [#{@logfile.id}] '#{@logfile.file_path}' claims #{@info[:csv_lines]} by us but only #{initial_lines_in_db} found in DB!"
      end
    end

    Rails.logger.info("Read #{@info[:csv_lines]} lines of '#{@logfile.file_path}' via CSV, launching thread to stream...")
    @info[:thread] = spawn_thread_to_read_continuously
    @info
  end

  def spawn_thread_to_read_continuously
    Thread.new do
      begin
        Thread.current[:lines_written] = @info[:csv_lines]

        ShellCommandStreamer.new(@logfile.shell_command_to_stream).stream!(spawn_stderr_reader: false) do |line, line_number|
          if line_number <= Thread.current[:lines_written]
            Rails.logger.info("Skipping #{line_number} for #{@logfile.basename} (will skip to #{Thread.current[:lines_written]}")
            next
          end

          line = line.gsub("\u0000", '').force_encoding(Encoding::UTF_8)  # Null byte...

          begin
            LogfileLine.where(logfile_id: @logfile.id, line_number: line_number, line: line).first_or_create!
          rescue ActiveRecord::ConnectionTimeoutError => e
            Rails.logger.warn("Connection timeout; sleeping and retrying")
            sleep 3
            retry
          rescue ActiveRecord::RecordNotUnique => e
            Rails.logger.error("#{e.class} while loading logfile #{@logfile.file_path} (id: #{@logfile.id}\nlineno. #{line_number}: #{line}")
            raise e
          end
        end
      rescue StandardError => e
        Rails.logger.error "#{e.class} in thread for '#{@logfile.file_path}': #{e.message}"
        raise e
      end
    end
  end
end
