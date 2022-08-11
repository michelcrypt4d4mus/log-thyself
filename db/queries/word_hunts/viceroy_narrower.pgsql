-- SELECT
--   msg_type_char(message_type, event_type) AS "T",
--   log_timestamp,
--   CASE WHEN process_name = 'com.apple.appkit.xpc.openAndSavePanelService' THEN 'openAndSavePanelService' ELSE process_name END AS process_name,

--   sender_process_name,
--   "category",
--   subsystem,
--   event_message

SELECT
  log_timestamp AT TIME ZONE 'utc'::text,
  COALESCE(event_type::VARCHAR, message_type::VARCHAR) AS "log_type",
  process_name,
  sender_process_name,
  category,
  subsystem
FROM macos_system_logs
WHERE event_type in ('activityCreateEvent', 'activityTransitionEvent')
  --AND (COALESCE(process_name, '') NOT IN ('com.apple.WebKit.WebContent', 'Safari', 'runningboardd'))
  AND process_name = 'avconferenced'
  AND log_timestamp > '2022-08-04T11:00:00'
  AND log_timestamp < '2022-08-05T10:00:00'
ORDER BY log_timestamp ASC
LIMIT 10000



SELECT
  log_timestamp AT TIME ZONE 'utc'::text,
  COALESCE(event_type::VARCHAR, message_type::VARCHAR) AS "log_type",
  process_name,
  sender_process_name,
  category,
  subsystem,
  event_message,
  process_id,
  activity_identifier,
  thread_id
FROM macos_system_logs
WHERE message_type IS NULL OR message_type <> 'Debug'
  --AND (COALESCE(process_name, '') NOT IN ('com.apple.WebKit.WebContent', 'Safari', 'runningboardd'))
  AND process_name = 'avconferenced'
  AND log_timestamp > '2022-08-04T11:00:00'
  AND log_timestamp < '2022-08-05T10:00:00'
ORDER BY log_timestamp ASC
LIMIT 1000

