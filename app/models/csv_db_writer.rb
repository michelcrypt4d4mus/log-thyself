# Writes ActiveRecord objects to the DB via CSV then COPY command (for speed)
# TODO: Move to lib/
# TODO: use postgres-copy gem with IO stream instead of writing to disk


require 'csv'
require 'fileutils'
require 'pp'
#require 'tempfile'  # Trying to use tempfile was a noble failure


class CsvDbWriter
  CSV_TMP_DIR = File.join(Rails.root, 'tmp', 'csv')
  BATCH_SIZE_DEFAULT = 100
  EXCLUDED_COLS = %w(id created_at updated_at)

  # Options:
  #   - batch_size: Number of lines to process between loads
  #   - avoid_dupes: avoid dupes (much slower)
  def initialize(model_klass, options = {})
    Rails.logger.debug("CSV Writer options: #{options}")
    @model_klass = model_klass
    @columns = model_klass.csv_columns
    @batch_size = options[:batch_size] || BATCH_SIZE_DEFAULT
    @avoid_dupes = options[:avoid_dupes] || false
    @rows_written = 0
    @rows_skipped = 0
  end

  # Block form of initialize
  def self.open(model_klass, options, &block)
    yield(writer = new(model_klass, options))
  ensure
    writer.close
  end

  def write(record)
    if @avoid_dupes && record.probably_exists_in_db?
      @rows_skipped += 1
      return
    end

    build_csv_writer unless @csv_writer
    @csv_writer << record.to_csv_hash
    @rows_written += 1

    if @rows_written % @batch_size == 0
      close_csv_and_copy_to_db
      build_csv_writer
    end
  end

  def close
    close_csv_and_copy_to_db
    Rails.logger.info("#{@rows_written} TOTAL lines written to #{@model_klass.table_name}.")
  end

  private

  def build_csv_writer
    @csv_stringio = StringIO.new
    @csv_writer ||= CSV.new(@csv_stringio, headers: @columns, write_headers: true, quote_char: '"')
  end

  def close_csv_and_copy_to_db
    return unless @csv_writer
    @model_klass.load_from_csv_string(@csv_stringio.string)
    @csv_writer.close
    @csv_writer = nil
    @csv_stringio.close
    @csv_stringio = nil
  end

  # def copy_query
  #   <<-SQL
  #     COPY #{@model_klass.table_name}
  #       (#{@columns.join(', ')})
  #     FROM '#{@csv_path}'
  #       CSV
  #       DELIMITER ','
  #       QUOTE '"'
  #       NULL AS ''
  #       HEADER;
  #   SQL
  # end
end
