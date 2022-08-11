-- Errors/faults
SELECT
  msg_type_char(message_type, event_type)  AS "L",
  RIGHT(process_name, 30) AS process_name,
  RIGHT(sender_process_name, 30) AS sender,
  LEFT("category", 25) AS "category",
  LEFT(subsystem, 55) AS subsystem,
  LEFT(event_message, 140),
  COUNT(*)
FROM macos_system_logs
WHERE message_type IN ('Error', 'Fault')
group by 1,2,3,4,5,6 order by 7 desc;
