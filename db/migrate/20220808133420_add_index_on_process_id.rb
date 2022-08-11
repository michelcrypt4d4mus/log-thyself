class AddIndexOnProcessId < ActiveRecord::Migration[7.0]
  def change
    add_index :macos_system_logs, :process_id
  end
end
