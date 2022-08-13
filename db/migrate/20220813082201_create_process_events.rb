# {
#   "event" : "ES_EVENT_TYPE_NOTIFY_EXIT",
#   "process" : {
#     "ancestors" : [
#       683,
#       1
#     ],
#     "signing info (computed)" : {
#       "signatureStatus" : 0,
#       "signatureSigner" : "AdHoc",
#       "signatureID" : "postgres-555549442905674728863a818cb7ba1aa51f4c34"
#     },
#     "uid" : 501,
#     "ppid" : 683,
#     "path" : "/opt/homebrew/Cellar/postgresql/14.4/bin/postgres",
#     "architecture" : "unknown",
#     "signing info (reported)" : {
#       "teamID" : "",
#       "csFlags" : 570425859,
#       "signingID" : "postgres-555549442905674728863a818cb7ba1aa51f4c34",
#       "platformBinary" : 0,
#       "cdHash" : "E863C98FD922D5C66A1A2B9A3BAF1C754F9A38AF"
#     },
#     "exit code" : 0,
#     "arguments" : [

#     ],
#     "pid" : 39369,
#     "name" : "postgres",
#     "rpid" : 683
#   },
#   "timestamp" : "2022-08-13 08:21:42 +0000"
# }

class CreateProcessEvents < ActiveRecord::Migration[7.0]
  def change
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
      t.timestamps
    end

    add_index :process_events, [:process_name, :event_type]
    add_index :process_events, :signature_signer
    add_index :process_events, :event_type
    add_index :process_events, :uid
  end
end
