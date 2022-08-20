module QueryStringHelper
  extend ActiveSupport::Concern

  DEFAULT_JOIN_STRING = ', '

  def double_quoted_join(array, join_string: DEFAULT_JOIN_STRING)
    quoted_join(array, '"', join_string: join_string)
  end

  def single_quoted_join(array, join_string: DEFAULT_JOIN_STRING)
    quoted_join(array, "'", join_string: join_string)
  end

  def quoted_join(array, quote_char, join_string: DEFAULT_JOIN_STRING)
    array.map { |element| "#{quote_char}#{element}#{quote_char}" }.join(join_string)
  end
end
