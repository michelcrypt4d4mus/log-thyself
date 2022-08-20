-- Fill in the WHERE
-- Requires ~300 columns of display space
SELECT
  COUNT(*) AS "cnt",
  TO_CHAR(MIN(log_timestamp), 'MonDD HH24:MI') AS first_seen,
  TO_CHAR(MAX(log_timestamp), 'MonDD HH24:MI') AS last_seen,
  msg_type_char(message_type, event_type)  AS "L",
  RIGHT(process_name, 22) AS process_name,
  RIGHT(sender_process_name, 22) AS sender,
  LEFT("category", 16) AS "category",
  RIGHT(subsystem, 35) AS subsystem,
  LEFT(redact_ids(event_message), 300) AS event_message
FROM macos_system_logs
WHERE event_message ~* 'microphone' -- sender_process_name <> 'CoreBrightness' AND process_name <> 'Activity Monitor'
   --AND log_timestamp > '2022-08-18T14:00:00'
GROUP BY 4,5,6,7,8,9
ORDER BY 1 DESC


--- Wirelessprox
SELECT
  COUNT(*) AS "count",
  msg_type_char(message_type, event_type)  AS "L",
  RIGHT(process_name, 22) AS process_name,
  RIGHT(sender_process_name, 22) AS sender,
  LEFT("category", 16) AS "category",
  RIGHT(subsystem, 35) AS subsystem,
  event_message AS event_message
FROM macos_system_logs
WHERE sender_process_name ~* 'WirelessProximity|WPDaemon|WPClient|WPDClient'
   OR event_message ~* 'WirelessProximity|WPDaemon|WPClient|WPDClient'
   OR subsystem ~* 'WirelessProximity|WPDaemon|WPClient|WPDClient'
   OR sender_process_name ~* 'RemoteDisplayDaemon'
   OR subsystem ~* 'RPRemoteDisplayDaemon'
   OR event_message ~* 'RemoteDisplayDaemon'
GROUP BY 2,3,4,5,6,7
ORDER BY 1 DESC;

WirelessProximity

-- With case-insensitive word hunt
SELECT
  COUNT(*) AS "count",
  msg_type_char(message_type, event_type)  AS "L",
  RIGHT(process_name, 22) AS process_name,
  RIGHT(sender_process_name, 22) AS sender,
  LEFT("category", 16) AS "category",
  RIGHT(subsystem, 35) AS subsystem,
  LEFT(redact_ids(event_message), 300) AS event_message
FROM macos_system_logs
 WHERE (
        COALESCE(process_name, '')
     || COALESCE(sender_process_name, '')
     || COALESCE(category, '')
     || COALESCE(subsystem, '')
     || COALESCE(event_message, '')
    ) ~* 'keyboard'
GROUP BY 2,3,4,5,6,7
ORDER BY 1 DESC


-- individual events
SELECT
  msg_type_char(message_type, event_type)  AS "L",
  log_timestamp,
  RIGHT(process_name, 30) AS process_name,
  process_id AS pid,
  RIGHT(sender_process_name, 30) AS sender,
  LEFT("category", 25) AS "category",
  RIGHT(subsystem, 53) AS subsystem,
  LEFT(event_message, 300)
FROM macos_system_logs
WHERE message_type >= 'Error'
ORDER BY log_timestamp DESC
