# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_08_15_062356) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "event_type_enum", ["activityCreateEvent", "logEvent", "stateEvent", "timesyncEvent", "activityTransitionEvent", "signpostEvent", "traceEvent", "userActionEvent"]
  create_enum "message_type", ["Debug", "Info", "Default", "Error", "Fault"]
  create_enum "message_type_enum", ["Debug", "Default", "Error", "Fault", "Info"]

  create_table "file_events", force: :cascade do |t|
    t.datetime "event_timestamp"
    t.string "event_type", comment: "See https://developer.apple.com/documentation/endpointsecurity/event_types"
    t.string "file"
    t.string "process_name", comment: "The process causing the event"
    t.integer "uid", limit: 2
    t.integer "pid"
    t.integer "ppid"
    t.integer "rpid", comment: "\"Real\" parent process ID"
    t.boolean "is_process_signed_as_reported"
    t.string "computed_signing_id"
    t.string "reported_signing_id", comment: "Only populated if it differs from the computed signature"
    t.json "raw_event"
    t.datetime "created_at", precision: nil, default: -> { "(now() AT TIME ZONE 'utc'::text)" }, null: false
    t.string "signature_signer"
    t.string "signature_authorities"
    t.string "process_arguments"
    t.index ["signature_signer"], name: "index_file_events_on_signature_signer"
  end

  create_table "logfile_lines", force: :cascade do |t|
    t.integer "logfile_id", null: false
    t.integer "line_number", null: false
    t.string "line", null: false
    t.datetime "created_at", precision: nil, default: -> { "(now() AT TIME ZONE 'utc'::text)" }, null: false
    t.index ["line"], name: "index_line_with_gin", opclass: :gin_trgm_ops, using: :gin
    t.index ["logfile_id", "line_number"], name: "index_logfile_lines_on_logfile_id_and_line_number", unique: true
  end

  create_table "logfiles", force: :cascade do |t|
    t.string "file_path", null: false
    t.datetime "file_created_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_path", "file_created_at"], name: "index_logfiles_on_file_path_and_file_created_at", unique: true
  end

  create_table "macos_system_logs", force: :cascade do |t|
    t.datetime "log_timestamp"
    t.enum "event_type", enum_type: "event_type_enum"
    t.enum "message_type", enum_type: "message_type"
    t.string "category"
    t.string "event_message"
    t.string "process_name"
    t.string "sender_process_name"
    t.string "subsystem"
    t.integer "process_id"
    t.integer "thread_id"
    t.decimal "trace_id", precision: 26, comment: "Max observed value was 20 digits"
    t.json "source"
    t.string "activity_identifier"
    t.integer "parent_activity_identifier"
    t.json "backtrace"
    t.string "process_image_path"
    t.string "sender_image_path"
    t.string "boot_uuid"
    t.string "process_image_uuid"
    t.string "sender_image_uuid"
    t.bigint "mach_timestamp"
    t.bigint "sender_program_counter"
    t.string "timezone_name"
    t.decimal "creator_activity_id", precision: 26, comment: "Max observed value was 20 digits"
    t.datetime "created_at", precision: nil, default: -> { "(now() AT TIME ZONE 'utc'::text)" }, null: false
    t.index ["category"], name: "index_macos_system_logs_on_category"
    t.index ["created_at"], name: "index_macos_system_logs_on_created_at"
    t.index ["event_message"], name: "index_msg_with_gin", opclass: :gin_trgm_ops, using: :gin
    t.index ["event_type"], name: "index_macos_system_logs_on_event_type"
    t.index ["log_timestamp", "event_type", "message_type", "category", "sender_process_name", "subsystem", "process_id"], name: "not_quite_unique_index"
    t.index ["message_type"], name: "index_macos_system_logs_on_message_type"
    t.index ["process_id"], name: "index_macos_system_logs_on_process_id"
    t.index ["process_image_path"], name: "index_macos_system_logs_on_process_image_path"
    t.index ["process_name"], name: "index_macos_system_logs_on_process_name"
    t.index ["sender_image_path"], name: "index_macos_system_logs_on_sender_image_path"
    t.index ["sender_process_name"], name: "index_macos_system_logs_on_sender_process_name"
    t.index ["subsystem"], name: "index_macos_system_logs_on_subsystem"
  end

  create_table "process_events", force: :cascade do |t|
    t.datetime "event_timestamp", null: false
    t.string "event_type", comment: "See https://developer.apple.com/documentation/endpointsecurity/event_types"
    t.string "process_path", null: false
    t.string "process_name", null: false
    t.string "process_arguments"
    t.integer "uid", limit: 2
    t.integer "pid", null: false
    t.integer "ppid"
    t.integer "rpid", comment: "\"Real\" parent process ID"
    t.integer "exit_code"
    t.boolean "is_process_signed_as_reported"
    t.string "signature_signer"
    t.string "signature_authorities"
    t.string "computed_signing_id"
    t.string "reported_signing_id", comment: "Only populated if it differs from the computed signature"
    t.json "raw_event"
    t.datetime "created_at", precision: nil, default: -> { "(now() AT TIME ZONE 'utc'::text)" }, null: false
    t.index ["event_timestamp"], name: "index_process_events_on_event_timestamp"
    t.index ["event_type"], name: "index_process_events_on_event_type"
    t.index ["process_name", "event_type"], name: "index_process_events_on_process_name_and_event_type"
    t.index ["signature_signer"], name: "index_process_events_on_signature_signer"
    t.index ["uid"], name: "index_process_events_on_uid"
  end

  create_function :random_int_between, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.random_int_between(low integer, high integer)
       RETURNS integer
       LANGUAGE sql
       IMMUTABLE PARALLEL SAFE STRICT LEAKPROOF COST 25
      AS $function$
        SELECT floor(random()* (high-low + 1) + low);
      $function$
  SQL
  create_function :msg_type_char, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.msg_type_char(message_type message_type, event_type event_type_enum)
       RETURNS character
       LANGUAGE sql
       IMMUTABLE PARALLEL SAFE LEAKPROOF
      AS $function$
        SELECT
          -- Most to least frequent for speed reasons
          CASE
            WHEN $1 = 'Debug'
              THEN 'D'
            WHEN $1 = 'Info'
              THEN 'I'
            WHEN $1 = 'Default'
              THEN '_'
            WHEN $2 = 'activityCreateEvent'
              THEN 'a'
            WHEN $1 = 'Error'
              THEN 'E'
            WHEN $1 = 'Fault'
              THEN 'F'
            WHEN $2 = 'stateEvent'
              THEN 's'
            WHEN $2 = 'timesyncEvent'
              THEN 't'
            WHEN $2 = 'activityTransitionEvent'
              THEN 'c'
            WHEN $2 = 'signpostEvent'
              THEN 'p'
            WHEN $2 = 'traceEvent'
              THEN 'r'
            WHEN $2 = 'userActionEvent'
              THEN 'u'
            WHEN $1 IS NULL AND $2 IS NULL
              THEN NULL
            ELSE
              '?'
            END
      $function$
  SQL
  create_function :redact_ids, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.redact_ids(a_string character varying)
       RETURNS character varying
       LANGUAGE sql
       IMMUTABLE PARALLEL SAFE LEAKPROOF
      AS $function$
        SELECT
          REGEXP_REPLACE(
            REGEXP_REPLACE(
              REGEXP_REPLACE(
                REGEXP_REPLACE($1, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '[redacted UUID]'),
                '0x[0-9A-Fa-f]+|[0-9A-Fa-f]{6,}', '[redacted hex]'
              ),
              'Hostname#[0-9a-f]+:\d+', '[redacted host]'
            ),
            '\d{3}-\d{3}-\D{4}', '[redacted ID]'
          )

      $function$
  SQL


  create_view "simplified_system_logs", sql_definition: <<-SQL
      SELECT macos_system_logs.log_timestamp,
      msg_type_char(macos_system_logs.message_type, macos_system_logs.event_type) AS "T",
      macos_system_logs.process_name,
      macos_system_logs.sender_process_name,
      macos_system_logs.category,
      macos_system_logs.subsystem,
      macos_system_logs.event_message
     FROM macos_system_logs;
  SQL
end
