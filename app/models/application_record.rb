class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Not definitive because of NULL vs. empty string...
  def probably_exists_in_db?
    raise "#{self.class} has not defined INDEX_SEARCH_COLS" unless defined?(INDEX_SEARCH_COLS)

    search_hash = INDEX_SEARCH_COLS.inject({}) do |memo, col|
      memo[col] = self[col].blank? ? nil : self[col]
      memo
    end

    self.class.where(search_hash).exists?
  end
end
