
-- DELETEd 1911977
DELETE FROM macos_system_logs
WHERE process_name = 'kernel'
  AND sender_process_name = 'AppleInputDeviceSupport'
  AND message_type = 'Debug'
  AND id % 1000 <> 1;

-- DELETEd 990450
DELETE FROM macos_system_logs
WHERE process_name = 'kernel'
  AND event_message LIKE '%failed lookup%'
  AND message_type = 'Default'
  AND id % 1000 <> 1;

-- Deleted 219063
DELETE FROM macos_system_logs
WHERE process_name = 'kernel'
  AND event_message LIKE 'ApplePPMPolicyCPMS::setDetailedThermalPowerBudget:setDetailedThermalPowerBudget%'
  AND message_type = 'Default'
  AND id % 1000 <> 1;

-- deleted 16111
DELETE FROM macos_system_logs
WHERE process_name = 'kernel'
  AND event_message LIKE 'cfil_acquire_sockbu%'
  AND id % 1000 <> 1;


DELETE FROM macos_system_logs
WHERE process_name = 'kernel'
  AND Message_type = 'Debug'
  AND sender_process_name = 'AppleS5L8920XPWM'
  AND id % 1000 <> 1;

AppleS5L8920XPWM
