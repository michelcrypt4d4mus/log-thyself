# Classes using this module may:
#    - implement validate_data_and_prepare_db!()
#    - implement transform_csv_data!()
#    - define PREFERRED_BATCH_SIZE
#    - define csv_converters() and header_converters() which will be passed to CSV.parse
#    - overload load_csv_data!()
#
# The default behavior is to use temp tables and the COPY command when loading data.

module PostgresCsvLoader
  extend ActiveSupport::Concern
  extend StyledNotifications
  include QueryStringHelper

  ID_COL = 'id'
  RAILS_TIMESTAMP_COLS = %w[created_at updated_at].freeze
  CSV_EXCLUDED_COLS = [ID_COL] + RAILS_TIMESTAMP_COLS

  included do |base|
    base::CSV_OPTIONS = {
      quote_char: '"',
      write_headers: true,
      headers: column_names - CSV_EXCLUDED_COLS
    }
  end

  class_methods do
    # TODO: we are generating and then parsing again... presumably we could skip that middle step?
    def load_from_csv_string(csv_string)
      csv_data = CSV.parse(csv_string, headers: true)
      transform_csv_data!(csv_data)

      ActiveRecord::Base.transaction do
        validate_data_and_prepare_db!(csv_data)
        load_csv_data!(csv_data)
      end
    end

    def csv_converters
      []
    end

    def header_converters
      []
    end

    # Abstract methods that are optional to implement
    def validate_data_and_prepare_db!(csv_data); end
    def transform_csv_data!(csv_data); end

    def columns_of_type(type)
      cols = columns_hash.select { |col, props| props.type == type }.keys
      cols - CSV_EXCLUDED_COLS
    end

    def csv_columns
      column_names - CSV_EXCLUDED_COLS
    end

    def preferred_batch_size
      defined?(self::PREFERRED_BATCH_SIZE) ? self::PREFERRED_BATCH_SIZE : CsvDbWriter::BATCH_SIZE_DEFAULT
    end

    private

    def cols_to_update
      cols = column_names - (defined?(self::UPSERT_KEYS) ? self::UPSERT_KEYS : Array.wrap(primary_key)) - %w[created_at]
      # Let the auto increment do its thing if the primary key is "id"
      primary_key == self::ID_COL ? cols - [self::ID_COL] : cols
    end

    def load_csv_data!(csv_data)
      tmp_table_name = "tmp_#{table_name}"
      copy_query = "COPY #{tmp_table_name} (#{csv_data.headers.join(',')}) FROM STDIN CSV"
      Rails.logger.debug("COPY query for #{self.class.to_s}:\n#{copy_query}")

      ActiveRecord::Base.connection.execute("
        DROP TABLE IF EXISTS #{tmp_table_name};
        CREATE TEMP TABLE #{tmp_table_name} (LIKE #{table_name} INCLUDING DEFAULTS INCLUDING IDENTITY) ON COMMIT DROP
      ")

      ActiveRecord::Base.connection.raw_connection.copy_data(copy_query) do
        csv_data.each do |line|
          ActiveRecord::Base.connection.raw_connection.put_copy_data(clean_and_encode(line.to_s))
        end
      end

      ActiveRecord::Base.connection.execute("
        INSERT INTO #{table_name}
            (#{double_quoted_join(csv_data.headers)})
          SELECT #{double_quoted_join(csv_data.headers)}
          FROM #{tmp_table_name}
          ON CONFLICT (#{(defined?(self::UPSERT_KEYS) ? self::UPSERT_KEYS : [primary_key]).join(',')})
          DO UPDATE SET
            (#{cols_to_update.join(',')}) =
            (#{cols_to_update.map { |c| "EXCLUDED.#{c}" }.join(',')});
      ")
    end
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
