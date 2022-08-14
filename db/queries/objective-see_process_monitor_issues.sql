-- with "source"
COPY(
  SELECT
    msg_type_char(message_type, event_type) AS "T",
    log_timestamp,
    process_name,
    sender_process_name,
    process_id,
    thread_id,
    "category",
    subsystem,
    event_message,
    source
  FROM macos_system_logs
  WHERE (
         sender_process_name ILIKE '%processmonitor%'
      OR process_name ILIKE '%processmonitor%'
      OR subsystem ILIKE '%processmonitor%'
      OR event_message ILIKE '%processmonitor%'
      OR source ILIKE '%processmonitor%'
    )
  ORDER BY log_timestamp DESC
)
TO '/tmp/objectivesee-processmonitor_EVERYTHING_2022-08-14T13.07PM.csv'--  (SELECT '/tmp/objectivesee-processmonitor-' || TO_CHAR(NOW(), 'YYYY-MM-DDTHH.MI.SS') || '.csv')
CSV
DELIMITER ','
QUOTE '"'
NULL AS ''
HEADER;

