module SharedMethods
  def say_key_value(key, value, indent: 8)
    say "#{key}: "
    say value, :cyan
  end
end
