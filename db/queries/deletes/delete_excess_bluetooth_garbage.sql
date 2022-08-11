-- Delete 99% of these records which are taking up like 50GB
-- There's a backup anyways

-- Getting counts
  -- SELECT
  --   msg_type_char(message_type, event_type) AS "L",
  --   process_name,
  --   sender_process_name,
  --   category,
  --   subsystem,
  --   event_message,
  --   COUNT(*)
  -- FROM macos_system_logs
  -- WHERE sender_process_name = 'BTAudioHALPlugin'
  --   AND message_type IN ('Error', 'Default')
  -- GROUP BY 1,2,3,4,5,6
  -- ORDER BY 7 DESC;

-- Deleting
-- Run 2022-08-08 after 8PM, maybe 60M-70M deleted?
-- Run again on 10th at 5:30PM, deleted 17M
DELETE
FROM macos_system_logs
WHERE sender_process_name = 'BTAudioHALPlugin'
  AND message_type IN ('Error', 'Default')
  AND category = 'BTAudio'
  AND subsystem = 'com.apple.bluetooth'
  AND log_timestamp > '2022-08-09'
  AND event_message IN (
    'Invalidating all (0) audio devices',
    'Register audio plugin connection with bluetoothd',
    'Starting BTAudioPlugin for <private>',
    'XPC server error: Connection invalid'
  )
  AND id % 100 <> 1;


-- Delete runaway activity monitor events collected from 8/7 to 8/10

-- Getting counts:
SELECT
  msg_type_char(message_type, event_type) AS "L",
  process_name,
  sender_process_name,
  category,
  subsystem,
  event_message,
  COUNT(*) AS "count"
FROM macos_system_logs
WHERE log_timestamp > '2022-08-07'
  AND category = 'strings'
  AND subsystem='com.apple.CFBundle'
  AND sender_process_name='CoreFoundation'
  AND process_name='Activity Monitor'
  AND message_type='Debug'
  AND event_message ~ 'table: Localizable, localizationName'
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC
LIMIT 2500;


-- DELETEs Run 2022-08-10 around 5:15PM
DELETE
FROM macos_system_logs
WHERE log_timestamp > '2022-08-07'
  AND category = 'strings'
  AND subsystem='com.apple.CFBundle'
  AND sender_process_name='CoreFoundation'
  AND process_name='Activity Monitor'
  AND message_type='Debug'
  AND event_message ~ 'table: Localizable, localizationName'
  AND id % 100 <> 1;


-- Deleted 4399711
DELETE
FROM macos_system_logs
WHERE log_timestamp > '2022-08-07'
  AND message_type = 'Debug'
  AND subsystem = 'com.apple.CarbonCore'
  AND category = 'checkfix'
  AND sender_process_name = 'CarbonCore'
  AND process_name = 'Activity Monitor'
  AND (
       event_message LIKE '%_CSCheckFix(10507300,com.apple.ActivityMonitor/1097)=NOT-APPLIED%'
    OR event_message LIKE '%_CSCheckFix(40356500,com.apple.ActivityMonitor/1097)=NOT-APPLIED%'
  )
  AND id % 100 <> 1;

DELETE
FROM macos_system_logs
WHERE log_timestamp > '2022-08-03'
  AND message_type = 'Debug'
  AND subsystem = 'com.apple.defaults'
  AND category = 'User Defaults'
  AND sender_process_name = 'CoreFoundation'
  AND process_name = 'Activity Monitor'
  AND (
       event_message LIKE 'found no value for key gpu-policies in CFPrefsPlistSourc%'
  )
  AND id % 100 <> 1;
