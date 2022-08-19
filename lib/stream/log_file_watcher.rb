# Watches logs from the old file system
# Re: tail args
#   -F handles log rotations with grace.
#   -50000000 should guarantee us the whole file.

require 'pastel'
require 'tty-table'


class LogFileWatcher
  extend StyledNotifications
  extend TableLogger

  POLL_INTERVAL_IN_SECONDS = 15

  class << self
    attr_accessor :streamer_threads
  end

  def self.load_and_stream_all_open_logfiles!
    load_and_stream_logfiles!(Logfile.open_logfiles)
  end

  def self.load_and_stream_logfiles!(logfiles)
    @streamer_threads = logfiles.inject({}) do |memo, logfile|
      memo[logfile] = new(logfile).load_and_stream!
      memo
    end

    @tty_table_data_old = []
    pastel = Pastel.new

    while(true) do
      sleep(POLL_INTERVAL_IN_SECONDS)
      log_state
    end
  end

  def self.log_state
    tty_table_header = ['ID', 'logfile path', 'alive?', 'Initial Load Lines', 'Lines Since Load']

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

    if tty_table_data != @tty_table_data_old
      table = TTY::Table.new(header: tty_table_header, rows: tty_table_data)
      table.orientation = :horizontal
      @tty_table_data_old = tty_table_data

      msg = "\n" + Pastel.new.underline("Status of log watcher threads") + Pastel.new.magenta.bold(" (new lines were read)")
      msg += "\n#{table.render(:unicode, **table_render_options)}\n"
      say_and_log(msg)
    else
      say_and_log("No lines read...")
    end
  end

  def initialize(logfile)
    logfile.save!
    @logfile = logfile
    @info = {}
  end

  # Returns a hash with the thread that was spawned and the lines loaded by initial CSV
  def load_and_stream!
    @info[:csv_lines] = @logfile.write_contents_to_db! || 0
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

        FileStreamer.new(@logfile.file_path, live_stream: true).stream! do |line, line_number|
          line = line.gsub("\u0000", '').force_encoding(Encoding::UTF_8)  # Null byte...
          next if line_number <= Thread.current[:lines_written]

          begin
            LogfileLine.where(logfile_id: @logfile.id, line_number: line_number, line: line).first_or_create!
          rescue ActiveRecord::ConnectionTimeoutError => e
            Rails.logger.warn("Connection timeout; sleeping and retrying")
            sleep 3
            retry
          rescue StandardError => e
            Rails.logger.error("#{e.class} while loading logfile #{@logfile.file_path} (id: #{@logfile.id}\nlineno. #{line_number}: #{line}")
            raise e
          end
        end

        Rails.logger.warn("STOPPED STREAMING!")
      rescue StandardError => e
        Rails.logger.error "#{e.class} in thread for '#{@logfile.file_path}': #{e.message}\n#{e.backtrace.join("\n")}"
        raise e
      end
    end
  end
end
