-- Ran 3:50AM Aug 11 deleted 3500558
DELETE FROM macos_system_logs
WHERE process_name = 'launchd'
  AND event_message LIKE 'failed lookup: name = com.apple.audio.audiohald%'
  AND id % 1000 <> 1

-- deleted 874461
DELETE FROM macos_system_logs
WHERE process_name = 'launchd'
  AND event_message LIKE 'Last log repeated %';

-- deleted ~900k
DELETE FROM macos_system_logs
WHERE process_name = 'launchd'
  AND event_message LIKE '%failed lookup%'
  AND message_type = 'Default'
  AND id % 100 <> 1

-- not much
DELETE FROM macos_system_logs
WHERE process_name = 'launchd'
  AND event_message ~ 'Flushed \d+ logs'
  AND id % 1000 <> 1;

--DELETE 1220889
DELETE FROM macos_system_logs
WHERE subsystem = 'com.apple.launchservices'
  AND (event_message LIKE 'MESSAGE: reply={result={LSBundlePath="/System/Library/Frameworks/WebKit.framework/Versions/A/XPCSer%'
  OR event_message LIKE 'MESSAGE: reply={result={CFBundleIdentifier="com.apple.WebKit.WebContent%'
  OR event_message LIKE 'MESSAGE: reply={success=false, } (for client 9600)%'
  OR event_message LIKE 'Error registering path <private>: -10822%'
  OR event_message LIKE 'Truncating a list of bindings%'
  OR event_message LIKE 'MESSAGE: reply={result={LSBundlePath%'
  OR event_message LIKE 'MESSAGE: reply={result={CFBundle%'
  OR event_message LIKE 'Destroying binding evaluato%'
  )
  AND id % 100 <> 1;
