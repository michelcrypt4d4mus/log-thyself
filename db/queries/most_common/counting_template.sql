-- Fill in the WHERE
-- Requires ~300 columns of display space
SELECT
  msg_type_char(message_type, event_type)  AS "L",
  RIGHT(process_name, 30) AS process_name,
  RIGHT(sender_process_name, 30) AS sender,
  LEFT("category", 25) AS "category",
  RIGHT(subsystem, 53) AS subsystem,
  LEFT(event_message, 140),
  COUNT(*)
FROM macos_system_logs
WHERE process_name = 'coreauthd'
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC;


-- Requires ~300 columns of display space
-- Fill in the WHERE
-- Requires ~300 columns of display space
SELECT
  msg_type_char(message_type, event_type)  AS "L",
  RIGHT(process_name, 30) AS process_name,
  RIGHT(sender_process_name, 30) AS sender,
  LEFT("category", 25) AS "category",
  RIGHT(subsystem, 53) AS subsystem,
  LEFT(event_message, 140),
  COUNT(*)
FROM macos_system_logs
WHERE process_name = 'coreauthd'
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC;


-- Requires ~300 columns of display space
SELECT
  msg_type_char(message_type, event_type)  AS "L",
  RIGHT(process_name, 20) AS process_name,
  RIGHT(sender_process_name, 20) AS sender,
  LEFT("category", 15) AS "category",
  RIGHT(subsystem, 30) AS subsystem,
  LEFT(event_message, 118),
  COUNT(*)
FROM macos_system_logs
WHERE log_timestamp > '2022-08-11'
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC;
