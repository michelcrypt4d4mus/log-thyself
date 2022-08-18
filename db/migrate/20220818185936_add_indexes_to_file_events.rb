class AddIndexesToFileEvents < ActiveRecord::Migration[7.0]
  def change
    add_index :file_events, :file
    add_index :file_events, [:process_name, :event_timestamp]
    add_index :file_events, :event_timestamp
    add_index :file_events, :uid
    add_index :file_events, :pid
    add_index :file_events, :ppid
    add_index :file_events, :rpid
    add_index :file_events, [:computed_signing_id]
  end
end
