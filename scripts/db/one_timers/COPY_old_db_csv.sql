COPY macos_system_logs (
    log_timestamp,
    event_type,
    message_type,
    category,
    event_message,
    process_name,
    sender_process_name,
    subsystem,
    process_id,
    thread_id,
    activity_identifier
)
-- Messed up the mapping for 26 Timesync events; loaded them separately.
FROM PROGRAM 'fgrep -v Timesync /Users/crypt4d4mus/workspace/macos_log_collector/tmp/old_db.csv'
CSV
DELIMITER ','
QUOTE '"'
NULL AS ''
HEADER;
