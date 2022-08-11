-- deleted 1291994
DELETE FROM macos_system_logs
WHERE process_name = 'corebrightnessd'
  AND message_type = 'Debug'
  AND id % 1000 <> 1;
