class AddUniquIshIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :macos_system_logs, %i(
      log_timestamp
      event_type
      message_type
      category
      sender_process_name
      subsystem
      process_id
    ), name: :not_quite_unique_index
  end
end
