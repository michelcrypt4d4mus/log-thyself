COPY (
  SELECT *
  FROM macos_system_logs
  where event_message ~* 'anon.*remote'
  order by log_timestamp ASC
)
TO '/tmp/anon_remote_EVERYTHING_2022-08-14T13.38PM.csv'
CSV
DELIMITER ','
QUOTE '"'
NULL AS ''
HEADER;
