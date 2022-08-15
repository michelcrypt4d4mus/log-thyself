SELECT
  msg_type_char(message_type, event_type) AS "L",
  log_timestamp,
  RIGHT(process_name, 35) AS process_name,
  RIGHT(sender_process_name, 25) AS process_name,
  LEFT(category, 25) AS category,
  LEFT(subsystem, 40) AS subsystem,
  LEFT(event_message, 150)  AS event_message,
  process_id,
  source
FROM macos_system_logs
WHERE log_timestamp >= '2022-08-05T00:25:06.819Z'
  AND (process_name || COALESCE(sender_process_name, '') || COALESCE(category, '') || COALESCE(subsystem, '') || COALESCE(event_message, '')) ~* '(av|audio|video|record|mic|conference|viceroy|call|remote)'
  AND COALESCE(event_message, '') !~* 'VSCode'
ORDER BY log_timestamp ASC
LIMIT 1000
