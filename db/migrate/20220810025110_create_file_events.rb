class CreateFileEvents < ActiveRecord::Migration[7.0]
  def up
    create_table :file_events do |t|
      t.datetime :event_timestamp
      t.string :event_type, comment: 'See https://developer.apple.com/documentation/endpointsecurity/event_types'
      t.string :file
      t.string :process_name, comment: 'The process causing the event'
      t.integer :uid, limit: 2
      t.integer :pid
      t.integer :ppid
      t.integer :rpid, comment: '"Real" parent process ID'
      t.boolean :is_process_signed_as_reported
      t.string :computed_signing_id
      t.string :reported_signing_id, comment: 'Only populated if it differs from the computed signature'
      t.json :raw_event
    end

    execute("""
      ALTER TABLE file_events
        ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc')
    """)
  end

  def down
    drop_table :file_events
  end
end
