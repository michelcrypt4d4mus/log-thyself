class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.columns_of_type(type)
    cols = columns_hash.select { |col, props| props.type == type }.keys
    (cols - CsvDbWriter::EXCLUDED_COLS)
  end
end
