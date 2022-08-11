-- DELETE 1248010
DELETE FROM macos_system_logs
WHERE process_name IN ('Safari', 'com.apple.WebKit.WebContent')
  AND message_type = 'Debug'
  AND id % 100 <> 1;


-- delete 892212
DELETE FROM macos_system_logs
WHERE process_name = 'com.apple.WebKit.WebContent'
  AND (
    event_message LIKE '%registering extension points inside framework%'
    OR event_message LIKE 'XPC error encountere%'
    OR event_message LIKE 'LaunchServices: disconnect event invalidation%'
    OR event_message LIKE 'Failed to find extension point%'
    OR event_message LIKE 'HTMLMediaElement%'
    OR event_message LIKE 'Current memory footprint%'
    OR event_message LIKE '%WebFrameLoaderClient::dispatchDidReachLay%'
    OR event_message LIKE '%DocumentLoader::DocumentLoader::stopLoading%'
  )
  AND message_type = 'Error'
  AND id % 1000 <> 1;


