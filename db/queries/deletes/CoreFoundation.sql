-- Deleted 1081985

DELETE FROM macos_system_logs
WHERE sender_process_name = 'CoreFoundation'
  AND (
  event_message LIKE 'found no value for key ResumableCopie%'
OR event_message LIKE 'Couldn''t open <private> due to No such file or director%'
OR event_message ~ 'WindowBorderMinBrightness'
OR event_message ~ 'Command1Through9SwitchesTabs'
OR event_message LIKE 'found no value for key %'
  )
  AND id % 1000 <> 1;

found no value for key ResumableCopie
