SELECT
  process_name,
  COUNT(*),
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_RENAME' THEN 1 END), 0) AS renames,
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_LINK' THEN 1 END), 0) AS links,
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_EXEC' THEN 1 END), 0) AS execs,
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_EXIT' THEN 1 END), 0) AS exits,
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_CREATE' THEN 1 END), 0) AS creates,
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_CLOSE' THEN 1 END), 0) AS closes,
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_OPEN' THEN 1 END), 0) AS opens,
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_UNLINK' THEN 1 END), 0) AS unlinks,
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_WRITE' THEN 1 END), 0) AS writes,
  COALESCE(SUM(CASE WHEN event_type = 'NOTIFY_FORK' THEN 1 END), 0) AS forks,
  COALESCE(SUM(CASE WHEN event_type IN ('NOTIFY_RENAME', 'NOTIFY_LINK', 'NOTIFY_EXEC', 'NOTIFY_EXIT', 'NOTIFY_CREATE', 'NOTIFY_CLOSE', 'NOTIFY_OPEN', 'NOTIFY_UNLINK', 'NOTIFY_WRITE', 'NOTIFY_FORK') THEN 0 ELSE 1 END), 0) AS UNKNOWN
FROM file_events
GROUP BY 1
ORDER BY 2 DESC