SELECT
  log_timestamp,
  msg_type_char(message_type, event_type) AS "T",
  process_name,
  sender_process_name,
  "category",
  subsystem,
  event_message
FROM macos_system_logs
