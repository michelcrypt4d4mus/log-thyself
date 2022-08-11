-- delete 48656
DELETE FROM macos_system_logs
WHERE subsystem = 'com.apple.securityd'
  AND event_message LIKE 'DataGetNext%'
  AND id % 10000 <> 1;
