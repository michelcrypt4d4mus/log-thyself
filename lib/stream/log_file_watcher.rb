# Watches logs from the old file system
# Re: tail args
#   -F handles log rotations with grace.
#   -50000000 should guarantee us the whole file.

require 'pastel'
require 'tty'

class LogFileWatcher
  attr_accessor :streamer_threads

  def load_and_stream!(logfile)
  end

  def load_and_stream!
    @streamer_threads = Logfile.open_logfiles.inject({}) do |memo, logfile|
      logfile.save!
      memo[logfile] = {}
      memo[logfile][:csv_lines] = logfile.write_contents_to_db!
      Rails.logger.info("Read #{memo[logfile][:csv_lines]} lines of '#{logfile.file_path}' via CSV, launching thread to stream from here...")

      memo[logfile][:thread] = Thread.new do
        begin
          Thread.current[:lines_written] = memo[logfile][:csv_lines]

          ShellCommandStreamer.new(logfile.shell_command_to_stream).stream! do |line, line_number|
            if line_number <= Thread.current[:lines_written]
              Rails.logger.info("Skipping #{line_number} for #{logfile.basename} (will skip to #{Thread.current[:lines_written]}")
            end

            line = line.gsub("\u0000", '').force_encoding(Encoding::UTF_8)  # Null byte...

            begin
              LogfileLine.where(logfile_id: logfile.id, line_number: line_number, line: line).first_or_create!
            rescue ActiveRecord::ConnectionTimeoutError => e
              Rails.logger.warn("Connection timeout; sleeping and retrying")
              sleep 3
              retry
            rescue ActiveRecord::RecordNotUnique => e
              Rails.logger.error("#{e.class} while loading logfile #{logfile.file_path} (id: #{logfile.id}\nlineno. #{line_number}: #{line}")
              raise e
            end
          end
        rescue => e
          Rails.logger.error "#{e.class} in thread for '#{logfile.file_path}': #{e.message}"
          raise e
        end
      end

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
end
