SELECT
  "T",
  process_name,
  sender_process_name,
  category,
  subsystem,
  event_message,
  COUNT(*)
FROM simplified_system_logs
WHERE (subsystem IS NULL OR subsystem NOT LIKE 'com.apple.%')
  AND process_name <> 'powerd'
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC
LIMIT 5000;