-- Fill in the WHERE
-- Requires ~300 columns of display space
SELECT
  COUNT(*) AS "count",
  msg_type_char(message_type, event_type)  AS "L",
  RIGHT(process_name, 22) AS process_name,
  RIGHT(sender_process_name, 22) AS sender,
  LEFT("category", 16) AS "category",
  RIGHT(subsystem, 35) AS subsystem,
  LEFT(redact_ids(event_message), 300) AS event_message
FROM macos_system_logs
WHERE log_timestamp > '2022-08-10'
GROUP BY 2,3,4,5,6,7
ORDER BY 1 DESC


-- individual events
SELECT
  msg_type_char(message_type, event_type)  AS "L",
  log_timestamp,
  RIGHT(process_name, 30) AS process_name,
  process_id AS pid,
  RIGHT(sender_process_name, 30) AS sender,
  LEFT("category", 25) AS "category",
  RIGHT(subsystem, 53) AS subsystem,
  LEFT(event_message, 300)
FROM macos_system_logs
WHERE log_timestamp > '2022-08-12'
  AND process_name='ProcessMonitor'
ORDER BY 2 DESC;

