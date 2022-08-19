# Writes ActiveRecord objects to the DB via CSV then COPY command (for speed)
# Basically acts as a buffer for rows headed to classes extending PostgresCsvLoader

require 'csv'


class CsvDbWriter
  include StyledNotifications
  attr_reader :csv_writer, :rows_written, :rows_skipped

  BATCH_SIZE_DEFAULT = 2_000

  # Options:
  #   - batch_size: Number of lines to process between loads
  #   - avoid_dupes: avoid dupes (much slower)
  def initialize(model_klass, options = {})
    Rails.logger.debug("CSV Writer options: #{options}")
    @model_klass = model_klass
    @batch_size = options[:batch_size] || BATCH_SIZE_DEFAULT
    @avoid_dupes = options[:avoid_dupes] || false
    @rows_written = @rows_skipped = 0
  end

  # Block form of initialize. Returns number of rows written.
  def self.open(model_klass, options = {}, &block)
    writer = new(model_klass, options)
    yield(writer)
    writer.rows_written
  ensure
    return unless writer.csv_writer
    writer.close
  end

  # :record should be an instance of @model_klass
  def <<(record)
    if @avoid_dupes && record.probably_exists_in_db?
      @rows_skipped += 1
      return
    end

    Rails.logger.debug("RECORD (#{record.class.to_s}) WRITTEN TO CsvWriter: #{record.attributes.pretty_inspect}")
    @csv_writer ||= build_csv_writer
    @csv_writer << record.to_csv_hash
    @rows_written += 1
    close_csv_and_copy_to_db if @rows_written % @batch_size == 0
  end

  # Load to DB and free resources
  def close_csv_and_copy_to_db
    @model_klass.load_from_csv_string(@csv_stringio.string)

    # subtract one from csv_writer.lineno because of the header row
    msg = "#{@csv_writer.lineno - 1} lines written to #{@model_klass.table_name} (#{@rows_written} total)"
    say_and_log(msg, styles: :dim)

    [@csv_writer, @csv_stringio].each { |io| io.close }
    @csv_writer = @csv_stringio = nil
  end
  alias :close :close_csv_and_copy_to_db

  private

  def build_csv_writer
    @csv_stringio = StringIO.new
    @csv_writer ||= CSV.new(@csv_stringio, **@model_klass::CSV_OPTIONS)
  end
end
