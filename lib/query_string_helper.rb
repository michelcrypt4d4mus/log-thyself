module QueryStringHelper
  #extend ActiveSupport::Concern

  DEFAULT_JOIN_STRING = ', '

  class << self
    def double_quoted_join(array, join_string: DEFAULT_JOIN_STRING)
      quoted_join(array, '"', join_string: join_string)
    end

    def single_quoted_join(array, join_string: DEFAULT_JOIN_STRING)
      quoted_join(array, "'", join_string: join_string)
    end

    def quoted_join(array, quote_char, join_string: DEFAULT_JOIN_STRING)
      array.map { |element| "#{quote_char}#{element}#{quote_char}" }.join(join_string)
    end

    def clean_and_encode(text)
      text.gsub("\u0000", '').force_encoding(Encoding::UTF_8)
    end

    def generate_enum_count_pivot_query(group_by, enum)
      selects = enum.map { |enum_string| condition_count_statement(enum_string) }
      unknown_criterion = "event_type NOT IN (#{FileEvent.single_quoted_join(types)})"
      selects << condition_count_statement('UNKNOWN', condition: unknown_criterion)

  <<-SQL
  SELECT
    "#{group_by}",
    COUNT(*),
    selects.join("\n  ")
  FROM #{table_name}
  GROUP BY 1
  ORDER BY 2 DESC
  SQL
    end

    private

    def condition_count_statement(enum_string, column, condition: nil)
      condition ||= "\|#{column}\| = '#{enum_string}'"
      "COALESCE(SUM(CASE WHEN #{condition} THEN 1 END), 0) AS #{enum_string.downcase.pluralize}"
    end
  end
end
