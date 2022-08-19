-- Note that anyone can put com.apple as the prefix for their process name,
-- so this really doesn't mean much.
SELECT
  "L",
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
