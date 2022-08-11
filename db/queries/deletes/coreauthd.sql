-- 1760675 deleted
DELETE FROM macos_system_logs
WHERE process_name = 'coreauthd'
  AND subsystem = 'com.apple.BiometricKit'
  AND (
       event_message LIKE 'BiometricKitXPCClient::interruptConnection%'
    OR event_message LIKE 'AssertMacros: err == 0 (value = 0x1003), file: /AppleInternal/Library/BuildRoots/20d6c351-ee94-11ec-bcaf-7247572f23b4%'
    OR event_message LIKE 'BiometricKitXPCClient::initWithDeviceType : connection invalidated%'
  )
  AND id % 1000 <> 1
