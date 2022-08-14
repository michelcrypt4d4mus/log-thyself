-- minute
SELECT
  TO_CHAR(log_timestamp, 'YYYY-MM-DD HH24:MI') AS "minute",
  COUNT(*)
FROM macos_system_logs
GROUP BY 1
ORDER BY 1 desc;

-- hour
SELECT
  TO_CHAR(log_timestamp, 'YYYY-MM-DD HH24:MI') AS "hour",
  COUNT(*)
FROM macos_system_logs
GROUP BY 1
ORDER BY 1 desc;

-- day
SELECT
  TO_CHAR(log_timestamp, 'YYYY-MM-DD') AS "day",
  COUNT(*)
FROM macos_system_logs
GROUP BY 1
ORDER BY 1 desc;
