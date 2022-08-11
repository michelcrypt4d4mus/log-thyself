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
WHERE log_timestamp >= '2022-08-05T00:25:06.819Z'
  AND log_timestamp < '2022-08-05T10:00:00'
  AND (process_name || COALESCE(sender_process_name, '') || COALESCE(category, '') || COALESCE(subsystem, '') || COALESCE(event_message, '')) ~* '(av|audio|video|mic|viceroy|call)'
  AND COALESCE(event_message, '') !~* 'VSCode'
ORDER BY log_timestamp ASC
LIMIT 1000

