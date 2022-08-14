-- with "source"
 select msg_type_char(message_type, event_type) AS "T",
     log_timestamp,
     process_name,
     sender_process_name,
     process_id,
     thread_id,
     "category",
     subsystem,
     event_message, backtrace,source FROM macos_system_logs where message_type NOT IN ('Debug', 'Info') AND   (sender_process_name ILIKE '%processmonitor%' OR process_name ILIKE '%processmonitor%' or subs
 ystem ILIKE '%processmonitor%' or event_message ILIKE '%processmonitor') order by log_timestamp desc;



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
    event_message
  FROM macos_system_logs
  WHERE log_timestamp > '2022-08-11'
    AND (
        process_id = 31265
    OR sender_process_name ~ 'processmonitor'
    OR process_name ~ 'processmonitor'
    OR event_message ~ 'processmonitor'
    )
  ORDER BY log_timestamp ASC
)
TO '/tmp/objectivesee-processmonitor_exceptions.csv'
CSV
DELIMITER ','
QUOTE '"'
NULL AS ''
HEADER;


-- All time
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
    event_message
  FROM macos_system_logs
  WHERE  (

       sender_process_name ~* 'processmonitor'
    OR process_name ~* 'processmonitor'
    OR event_message ~* 'processmonitor'
    OR event_message ~* 'objective-see'
    )
  ORDER BY log_timestamp ASC
)TO '/tmp/objectivesee-processmonitor_alltime_activity.csv'
CSV
DELIMITER ','
QUOTE '"'
NULL AS ''
HEADER;
