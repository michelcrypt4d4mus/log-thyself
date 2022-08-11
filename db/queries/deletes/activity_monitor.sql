-- deleted 1261339
DELETE FROM macos_system_logs
WHERE process_name = 'Activity Monitor'
  AND message_type = 'Debug'
  AND id <> 1000;
