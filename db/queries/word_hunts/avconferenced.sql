 SELECT
  id,
  log_timestamp AT TIME ZONE 'utc'::text,
  COALESCE(event_type::VARCHAR, message_type::VARCHAR) AS "log_type",
  event_message,
  process_name,
  sender_process_name,
  category,
  subsystem,
  process_id,
  activity_identifier,
  thread_id
FROM macos_system_logs
WHERE process_name = 'avconferenced'
   OR sender_process_name = 'avconferenced'
ORDER BY log_timestamp ASC
LIMIT 5000