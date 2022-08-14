class ChangeSourceColumnToJson < ActiveRecord::Migration[7.0]
  def change
    execute("UPDATE macos_system_logs SET source = NULL WHERE source IS NOT NULL")
    change_column(:macos_system_logs, :source, :json, using: 'source::json')
  end
end
