SELECT
  "T",
  process_name,
  sender_process_name,
  "category",
  subsystem,
  event_message,
  COUNT(*)
FROM simplified_system_logs
WHERE process_name ILIKE 'viceroy'
    OR sender_process_name ILIKE 'viceroy'
    OR category ILIKE 'viceroy'
    OR subsystem ILIKE 'viceroy'
    OR event_message ILIKE 'viceroy'
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC;
