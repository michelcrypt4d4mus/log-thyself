# TODO: Almost all of this stuff should live on PostgresCsvLoader

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  ID_COL = 'id'
  RAILS_TIMESTAMP_COLS = %w[created_at updated_at].freeze
  CSV_EXCLUDED_COLS = [ID_COL] + RAILS_TIMESTAMP_COLS

  def self.csv_columns
    column_names - CSV_EXCLUDED_COLS
  end

  def self.columns_of_type(type)
    cols = columns_hash.select { |col, props| props.type == type }.keys
    cols - CSV_EXCLUDED_COLS
  end

  # Attribute hash with keys of string type plus timestamps
  def to_csv_hash
    row = attributes.except(*CSV_EXCLUDED_COLS)

    # Preserve precision for timestamps, stringify json
    self.class.columns_of_type(:datetime).each { |col| row[col] = row[col].iso8601(6) }
    self.class.columns_of_type(:json).each { |col| row[col] = row[col].to_json }

    row
  end
end
