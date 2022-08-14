SELECT
  msg_type_char(message_type, event_type) AS "T",
  log_timestamp,
  process_name,
  sender_process_name,
  process_id,
  thread_id,
  "category",
  subsystem,
  event_message
FROM macos_system_logs
WHERE (
      sender_process_name ~* 'voice'
   OR process_name ~* 'voice'
   OR event_message ~* 'voice'
   OR category ~* 'voice'
   OR subsystem ~* 'voice'
)
ORDER BY log_timestamp ASC limit 500
