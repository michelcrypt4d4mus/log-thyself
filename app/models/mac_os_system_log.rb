class MacOsSystemLog < ApplicationRecord
  self.table_name = 'macos_system_logs'

  # Not loaded into DB
  EXCLUDED_KEYS = %w(formatString)
  JSON_COLUMN_NAME_SYMBOLS = column_names.map(&:to_sym) - %i(id created_at updated_at)

  # For queries on uniquess (sort of)
  INDEX_SEARCH_COLS = %i(
    log_timestamp
    event_type
    message_type
    category
    sender_process_name
    subsystem
    process_id
  )

  # To derive the columne named by the key, split the column named by value by '/' and take last
  DERIVED_FROM_END_OF_PATH = {
    process_name: :process_image_path,
    sender_process_name: :sender_image_path
  }

  # Construct an instance of MacOsSystemLog from JSON
  def self.from_json(log_json)
    row_hash = log_json.inject({}) do |row, (k, v)|
      next row if EXCLUDED_KEYS.include?(k)
      v = v.strip.tr("\r\n\t", ' ').gsub(/\s+/, ' ') if v&.is_a?(String)  # Collapse whitespace

      if k == 'timestamp'
        row[:log_timestamp] = v  # rename to ease queries ("timestamp" needs to be in quotes)
      else
        row[k.underscore.to_sym] = v
      end

      row
    end

    DERIVED_FROM_END_OF_PATH.each do |k, v|
      row_hash[k] = row_hash[v].split('/').last unless row_hash[v].blank?
    end

    unless (row_hash.keys - JSON_COLUMN_NAME_SYMBOLS).empty?
      Rails.logger.error("Key #{k} in data but no col. Row:\n#{row_hash.pretty_inspect}")
    end

    new(row_hash)
  end

  # Not definitive...
  def probably_exists_in_db?
    search_hash = INDEX_SEARCH_COLS.inject({}) do |memo, col|
      memo[col] = self[col].blank? ? nil : self[col]
      memo
    end

    self.class.where(search_hash).exists?
  end
end
