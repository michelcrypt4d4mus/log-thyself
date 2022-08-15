SELECT
  msg_type_char(message_type, event_type) AS "L",
  log_timestamp,
  process_name,
  process_id,
  sender_process_name,
  "category",
  subsystem,
  event_message
FROM macos_system_logs
