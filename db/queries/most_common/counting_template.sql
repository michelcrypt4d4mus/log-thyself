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
WHERE "source" = '{"symbol"=>"", "line"=>0, "image"=>"powerd", "file"=>""}'
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC;
