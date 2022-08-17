SELECT
  msg_type_char(message_type, event_type) AS "L",
  log_timestamp,
  process_name AS process,
  process_id AS pid,
  sender_process_name AS sender,
  "category",
  subsystem,
  event_message
FROM macos_system_logs
