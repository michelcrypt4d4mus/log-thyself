DELETE FROM macos_system_logs
WHERE sender_process_name = 'CFNetwork'
  AND event_message LIKE '%: summary for unused connection {protocol%'
  AND id % 1000 <> 1;

