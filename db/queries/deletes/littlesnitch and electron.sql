-- 1973467
DELETE FROM macos_system_logs
WHERE process_name IN ('Little Snitch Agent', 'Electron')
  AND message_type = 'Debug'
  AND id % 100 <> 1;
