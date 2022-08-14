# Writes ActiveRecord objects to the DB via CSV then COPY command (for speed)
# TODO: Move to lib/

require 'csv'


class CsvDbWriter
  include StyledNotifications

  BATCH_SIZE_DEFAULT = 1_000
  #EXCLUDED_COLS = %w(id created_at updated_at)  Maybe this does belong here...

  attr_reader :csv_writer

  # Options:
  #   - batch_size: Number of lines to process between loads
  #   - avoid_dupes: avoid dupes (much slower)
  def initialize(model_klass, options = {})
    Rails.logger.debug("CSV Writer options: #{options}")
    @model_klass = model_klass
    @csv_options = PostgresCsvLoader::CSV_OPTIONS.merge(headers: @model_klass.csv_columns)
    @batch_size = options[:batch_size] || BATCH_SIZE_DEFAULT
    @avoid_dupes = options[:avoid_dupes] || false

    # Keep some running counts
    @rows_written = @rows_skipped = 0
  end

  # Block form of initialize
  def self.open(model_klass, options, &block)
    writer = new(model_klass, options)
    yield(writer)
  ensure
    writer.close if writer.csv_writer
  end

  # :record should be an instance of @model_klass
  def <<(record)
    if @avoid_dupes && record.probably_exists_in_db?
      @rows_skipped += 1
      return
    end

    build_csv_writer unless @csv_writer
    @csv_writer << record.to_csv_hash
    @rows_written += 1
    close_csv_and_copy_to_db if @rows_written % @batch_size == 0
  end

  # Load to DB and free resources
  def close_csv_and_copy_to_db
    @model_klass.load_from_csv_string(@csv_stringio.string)

    # -1 because of the header row
    msg = "#{@csv_writer.lineno - 1} lines written to #{@model_klass.table_name} (#{@rows_written} total)"
    say_and_log(msg, styles: :dim)
    [@csv_writer, @csv_stringio].each { |io| io.close }
    @csv_writer = @csv_stringio = nil
  end
  alias :close :close_csv_and_copy_to_db

  private

  def build_csv_writer
    @csv_stringio = StringIO.new
    @csv_writer ||= CSV.new(@csv_stringio, **@csv_options)
  end
end
