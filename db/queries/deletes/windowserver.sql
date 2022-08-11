-- Rand aug 11 3AM, deleted 3,118,832
DELETE FROM macos_system_logs
WHERE process_name = 'WindowServer'
  AND sender_process_name IN ('MultitouchHID', 'ColourSensorFilterPlugin', 'IOKit')
  AND message_type = 'Debug'
  AND id % 100 <> 1

-- DELETE 2828037
delete from macos_system_logs
where process_name ='WindowServer'
  and message_type = 'Debug'
  AND id % 100 <> 1
