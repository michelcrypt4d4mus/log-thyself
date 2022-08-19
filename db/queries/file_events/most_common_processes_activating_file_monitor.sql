select
  process_name,
  COUNT(*),
  MIN(event_timestamp) AS first_activity_at,
  MAX(event_timestamp) AS last_activity_at
FROM file_events
WHERE event_timestamp > '2022-08-19T12:00:00'
GROUP BY 1
order by 2 desc;
