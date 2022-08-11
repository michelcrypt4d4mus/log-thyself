class CreateFunctionRandomIntFunction < ActiveRecord::Migration[7.0]
  def change
    create_function :random_int_function
  end
end
