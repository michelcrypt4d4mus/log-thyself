-- not much
DELETE FROM macos_system_logs
WHERE process_name = 'coreaudiod'
  AND message_type = 'Debug'
  AND id % 1000 <> 1;

-- Deleted 1289035
DELETE FROM macos_system_logs
WHERE sender_process_name = 'BTAudioHALPlugin'
  AND id % 1000 <> 1;
