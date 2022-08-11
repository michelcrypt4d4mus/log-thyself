-- Event counts by hour
SELECT
  TO_CHAR(log_timestamp, 'YYYY-MM-DD HH24') AS "hour",
  SUM(CASE WHEN message_type ='Debug' THEN 1 END) AS Debugs,
  SUM(CASE WHEN message_type ='Default' THEN 1 END) AS Defaults,
  SUM(CASE WHEN message_type ='Error' THEN 1 END) AS Errors,
  SUM(CASE WHEN message_type ='Fault' THEN 1 END) AS Faults,
  SUM(CASE WHEN message_type ='Info' THEN 1 END) AS Infos,
  SUM(CASE WHEN message_type IS NULL THEN 1 END) AS events
FROM macos_log_collector_development
GROUP BY 1
ORDER BY 1 DESC;