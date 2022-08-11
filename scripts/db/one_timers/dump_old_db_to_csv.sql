COPY (
  SELECT
    log_line_timestamp,

    CASE
      WHEN log_type = 'Activity' THEN
        'activityCreateEvent'
      WHEN log_type = 'State' THEN
        'stateEvent'
      WHEN log_type = 'Timesync' THEN
        'timesyncEvent'
      WHEN log_type = 'UserAction' THEN
        'userActionEvent'
      ELSE
        'logEvent'
      END AS event_type,

    CASE
      WHEN log_type IN ('Activity','Timesyn','State','Timesyn','UserAction') THEN
        NULL
      ELSE
        log_type
      END AS message_type,

    SPLIT_PART(process_package_label, ':', 2) AS category,
    TRIM(REGEXP_REPLACE(msg, '\s+', ' ', 'g')) AS event_message,
    process_name,
    process_location AS sender_process_name,
    SPLIT_PART(process_package_label, ':', 1) AS subsystem,
    process_id,
    hex_to_int(thread_id) AS thread_id,
    hex_to_int(activity) AS activity_identifier
  FROM macos_system_logs
)
TO '/Users/crypt4d4mus/workspace/macos_log_collector/tmp/old_db.csv'
CSV
DELIMITER ','
QUOTE '"'
NULL AS ''
HEADER;
