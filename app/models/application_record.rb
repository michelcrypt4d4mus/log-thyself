class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  RAILS_TIMESTAMP_COLS = %w[created_at updated_at].freeze
  CSV_EXCLUDED_COLS = %w[id] + RAILS_TIMESTAMP_COLS

  def self.csv_columns
    column_names - CsvDbWriter::EXCLUDED_COLS
  end

  def self.columns_of_type(type)
    cols = columns_hash.select { |col, props| props.type == type }.keys
    cols - CsvDbWriter::EXCLUDED_COLS
  end

  # Preserve precision for timestamps, stringify json
  def to_csv_hash(set_timestamps_to_now = false)
    row = attributes.except(*CSV_EXCLUDED_COLS)
    self.class.columns_of_type(:datetime).each { |col| row[col] = row[col].iso8601(6) }
    self.class.columns_of_type(:json).each { |col| row[col] = row[col].to_json }

    if set_timestamps_to_now
      (RAILS_TIMESTAMP_COLS & self.class.column_names).each { |c| row[c] = 'NOW()' }
    end

    row
  end
end
