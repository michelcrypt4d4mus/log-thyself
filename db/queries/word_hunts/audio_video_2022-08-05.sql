-- MBA 2
SELECT
  COUNT(*) AS "cnt",
  TO_CHAR(MIN(log_timestamp), 'MonDD HH24:MI') AS first_seen,
  TO_CHAR(MAX(log_timestamp), 'MonDD HH24:MI') AS last_seen,
  msg_type_char(message_type, event_type)  AS "L",
  RIGHT(process_name, 22) AS process_name,
  RIGHT(sender_process_name, 22) AS sender,
  LEFT("category", 16) AS "category",
  RIGHT(subsystem, 25) AS subsystem,
  LEFT(redact_ids(event_message), 300) AS event_message
FROM macos_system_logs
WHERE log_timestamp < '2022-08-15' AND event_message ~* 'microphone|camera' AND event_message !~* 'parallels'
  --AND log_timestamp > '2022-08-18T14:00:00'
GROUP BY 4,5,6,7,8,9
ORDER BY 1 DESC



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
  AND (COALESCE(process_name, '') || COALESCE(sender_process_name, '') || COALESCE(category, '') || COALESCE(subsystem, '') || COALESCE(event_message, '')) ~* '(av|audio|video|record|mic|conference|viceroy|call|remote)'
  AND COALESCE(event_message, '') !~* 'VSCode'
ORDER BY log_timestamp ASC
LIMIT 1000


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
  AND (COALESCE(process_name, '') || COALESCE(sender_process_name, '') || COALESCE(category, '') || COALESCE(subsystem, '') || COALESCE(event_message, '')) ~* 'BBWriter'
  AND COALESCE(event_message, '') !~* 'VSCode'
ORDER BY log_timestamp ASC
LIMIT 1000


