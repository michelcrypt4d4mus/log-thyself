class CreateProcessEvents < ActiveRecord::Migration[7.0]
  def up
    create_table :process_events do |t|
      t.datetime :event_timestamp, null: false
      t.string :event_type, comment: 'See https://developer.apple.com/documentation/endpointsecurity/event_types'
      t.string :process_path, null: false
      t.string :process_name, null: false
      t.string :process_arguments
      t.integer :uid, limit: 2
      t.integer :pid, null: false
      t.integer :ppid
      t.integer :rpid, comment: '"Real" parent process ID'
      t.integer :exit_code
      t.boolean :is_process_signed_as_reported
      t.string :signature_signer
      t.string :signature_authorities
      t.string :computed_signing_id
      t.string :reported_signing_id, comment: 'Only populated if it differs from the computed signature'
      t.json :raw_event
    end

    execute("""
      ALTER TABLE process_events
        ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc')
    """)

    add_index :process_events, :event_timestamp
    add_index :process_events, [:process_name, :event_type]
    add_index :process_events, :signature_signer
    add_index :process_events, :event_type
    add_index :process_events, :uid
  end

  def down
    drop_table :process_events
  end
end
