-- Event counts by hour
SELECT
  TO_CHAR(log_timestamp, 'YYYY-MM-DD FMHHAM') AS "hour",
  COALESCE(SUM(CASE WHEN message_type ='Debug' THEN 1 END), 0) AS Debugs,
  COALESCE(SUM(CASE WHEN message_type ='Default' THEN 1 END), 0) AS Defaults,
  COALESCE(SUM(CASE WHEN message_type ='Error' THEN 1 END), 0) AS Errors,
  COALESCE(SUM(CASE WHEN message_type ='Fault' THEN 1 END), 0) AS Faults,
  COALESCE(SUM(CASE WHEN message_type ='Info' THEN 1 END), 0) AS Infos,
  COALESCE(SUM(CASE WHEN message_type IS NULL THEN 1 END), 0) AS events,
  COUNT(*) AS total
FROM macos_system_logs
GROUP BY 1
ORDER BY 1 DESC;



-- By Day
SELECT
  TO_CHAR(log_timestamp, 'YYYY-MM-DD') AS "hour",
  COALESCE(SUM(CASE WHEN message_type ='Debug' THEN 1 END), 0) AS Debugs,
  COALESCE(SUM(CASE WHEN message_type ='Default' THEN 1 END), 0) AS Defaults,
  COALESCE(SUM(CASE WHEN message_type ='Error' THEN 1 END), 0) AS Errors,
  COALESCE(SUM(CASE WHEN message_type ='Fault' THEN 1 END), 0) AS Faults,
  COALESCE(SUM(CASE WHEN message_type ='Info' THEN 1 END), 0) AS Infos,
  COALESCE(SUM(CASE WHEN message_type IS NULL THEN 1 END), 0) AS events,
  COUNT(*) AS total
FROM macos_system_logs
GROUP BY 1
ORDER BY 1 DESC;


-- By process
SELECT
  process_name,
  COALESCE(SUM(CASE WHEN message_type ='Debug' THEN 1 END), 0) AS Debugs,
  COALESCE(SUM(CASE WHEN message_type ='Default' THEN 1 END), 0) AS Defaults,
  COALESCE(SUM(CASE WHEN message_type ='Error' THEN 1 END), 0) AS Errors,
  COALESCE(SUM(CASE WHEN message_type ='Fault' THEN 1 END), 0) AS Faults,
  COALESCE(SUM(CASE WHEN message_type ='Info' THEN 1 END), 0) AS Infos,
  COALESCE(SUM(CASE WHEN message_type IS NULL THEN 1 END), 0) AS events,
  COUNT(*) AS total
FROM macos_system_logs
GROUP BY 1
ORDER BY 8 DESC;
