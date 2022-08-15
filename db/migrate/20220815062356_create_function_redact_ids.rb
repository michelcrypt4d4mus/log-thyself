class CreateFunctionRedactIds < ActiveRecord::Migration[7.0]
  def change
    create_function :redact_ids
  end
end
