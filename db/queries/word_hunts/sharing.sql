SELECT
  msg_type_char(message_type, event_type) AS "T",
  process_name,
  LEFT(sender_process_name, 30),
  category,
  LEFT(subsystem, 30) AS subsystem,
  LEFT(event_message, 100) AS msg,
  COUNT(*)
FROM macos_system_logs
WHERE event_message ~* 'sharing' GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC;
