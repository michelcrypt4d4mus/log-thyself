-- deleted 254239
DELETE FROM macos_system_logs
WHERE process_name = 'runningboardd'
  AND event_message IN (
    'state update',
    'timer',
    'acquireAssertionWithDescriptor',
    'state update',
    'invalidateAssertionWithIdentifier',
    'timer',
    'acquireAssertionWithDescriptor',
    'state notification',
    'invalidateAssertionWithIdentifier',
    'state notification',
    'limitationsForInstance',
    'lookupHandleForPredicate'
  )
  AND id % 100 <> 1;

-- deleted 924000
DELETE FROM macos_system_logs
WHERE process_name = 'runningboardd'
  AND message_type = 'Debug'
  AND id % 100 <> 1;
