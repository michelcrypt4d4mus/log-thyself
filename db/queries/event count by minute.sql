select
  to_char(log_timestamp, 'YYYY-MM-DD HH24:MI'),
  COUNT(*) AS "HOUR"
FROM macos_system_logs
group by 1 order by 1 desc;
