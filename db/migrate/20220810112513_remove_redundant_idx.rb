class RemoveRedundantIdx < ActiveRecord::Migration[7.0]
  def change
    remove_index :macos_system_logs, :log_timestamp
  end
end
