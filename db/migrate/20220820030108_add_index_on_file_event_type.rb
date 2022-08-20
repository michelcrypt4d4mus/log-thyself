class AddIndexOnFileEventType < ActiveRecord::Migration[7.0]
  def change
    add_index :file_events, [:event_type, :process_name]
  end
end
