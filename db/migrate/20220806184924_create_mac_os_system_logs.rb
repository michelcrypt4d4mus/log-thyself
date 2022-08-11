class CreateMacOsSystemLogs < ActiveRecord::Migration[7.0]
  COLS_TO_INDEX = %w(
    log_timestamp
    event_type
    message_type
    subsystem
    category
    process_image_path
    sender_image_path
    process_name
    sender_process_name
    created_at
  )

  def up
    create_table(:macos_system_logs) do |t|
      t.column :log_timestamp, :datetime
      t.column :event_type, :string
      t.column :message_type, :string
      t.column :category, :string
      t.column :event_message, :string
      # Derived
      t.column :process_name, :string
      t.column :sender_process_name, :string
      # Process related
      t.column :subsystem, :string
      t.column :process_id, :string
      t.column :thread_id, :string
      t.column :trace_id, :decimal, precision: 26, scale: 0
      t.column :source, :string
      t.column :activity_identifier, :string
      t.column :parent_activity_identifier, :decimal, precision: 26, scale: 0
      t.column :backtrace, :json
      # File paths
      t.column :process_image_path, :string
      t.column :sender_image_path, :string
      # UUIDs
      t.column :boot_uuid, :string
      t.column :process_image_uuid, :string
      t.column :sender_image_uuid, :string
      # ???
      t.column :mach_timestamp, :bigint
      t.column :sender_program_counter, :bigint
      t.column :timezone_name, :string
      t.column :creator_activity_id, :decimal, precision: 26, scale: 0
    end

    execute("""
      ALTER TABLE macos_system_logs
        ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc')
    """)

    COLS_TO_INDEX.each { |col| add_index :macos_system_logs, col.to_sym }
  end

  def down
    drop_table :macos_system_logs
  end
end
