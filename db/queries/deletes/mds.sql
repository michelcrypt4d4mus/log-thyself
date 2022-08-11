-- 2022-08-11 Deleted 2,142,178
DELETE FROM macos_system_logs
WHERE process_name = 'mds'
  AND subsystem = 'com.apple.spotlightserver'
  AND message_type = 'Debug'
  AND (
      event_message ~ 'NEXTQUEUE'
    OR event_message ~ 'REORDER CHANGE'
    OR event_message ~ 'tryToPopQueue'
    OR event_message ~ 'handleXPCMessage'
    OR event_message ~ 'MDSRemoteIndexWrapper messageName'
    OR event_message ~ '---- No queues available'
    OR event_message ~ '---- No minimum bank'
    OR event_message ~ 'finished with status 0'
    OR event_message ~ 'fetchAttributes'
    OR event_message ~ 'seconds on scheduler'
    OR event_message ~ 'ADD queue:0x'
    OR event_message ~ 'MDSRemoteIndexWrapper messageName'
    OR event_message ~ '---- No queues available'
  )
  AND id % 100 <> 1;


  AND
 D | mds          |                                | QOS           | com.apple.spotlightserver    | MDSRemoteIndexWrapper messageName:<private> qos: 0x11                                                                                        | 466586
 D | mds          |                                | ImportServer  | com.apple.spotlightserver    | ---- No queues available                                                                                                                     | 214169
 D | mds          |                                | Server        | com.apple.spotlightserver    | NEXTQUEUE:0x0 blocked:0                                                                                                                      | 214125
 D | mds          |                                | ImportServer  | com.apple.spotlightserver    | ---- No minimum bank, or can't issue work:0x14f962ea0                                                                                        | 202779
 D | mds          |                                | Server        | com.apple.spotlightserver    | NEXTQUEUE:0x1500ec200 blocked:0                                                                                                              | 122293
 D | mds          |                                | Server        | com.apple.spotlightserver    | REORDER CHANGE queue:0x1500ec200 band:0x14f962ea0 newState:0                                                                                 | 112506
 D | mds          |                                | ImportServer  | com.apple.spotlightserver    | EVAL why:2 blocked:0 migration:0 band:0x14f962ea0 hasWork:1 canIssue:1 priority:30 firstQueue:0x1500ec200 queueCount:1                       | 112496
 D | mds          |                                | Server        | com.apple.spotlightserver    | REORDER CHANGE queue:0x1500ec200 band:0x14f962ea0 newState:1                                                                                 | 112482
 D | mds          |                                | Server        | com.apple.spotlightserver    | NEXTQUEUE:0x14f063400 blocked:0                                                                                                              |  96286
 D | mds          |                                | Server        | com.apple.spotlightserver    | REORDER CHANGE queue:0x14f063400 band:0x14f962ea0 newState:0                                                                                 |  88986
 D | mds          |                                | ImportServer  | com.apple.spotlightserver    | EVAL why:2 blocked:0 migration:0 band:0x14f962ea0 hasWork:1 canIssue:1 priority:30 firstQueue:0x14f063400 queueCount:1                       |  88933
 D | mds          |                                | Server        | com.apple.spotlightserver    | REORDER CHANGE queue:0x14f063400 band:0x14f962ea0 newState:1                                                                                 |  88878
 D | mds          |                                | Task          | com.apple.spotlightserver    | Task <private> finished with status 0                                                                                                        |  52968
 D | mds          |                                | ImportServer  | com.apple.spotlightserver    | ---- tryToPopQueue -> true : 147                                                                                                             |  32190
 D | mds          |                                | ImportServer  | com.apple.spotlightserver    | ---- tryToPopQueue -> true : 146                                                                                                             |  20130
 D | mds          | mds                            | Message       | com.apple.spotlightserver    | handleXPCMessage: <private>                                                                                                                  |  15834
 D | mds          |                                | ImportServer  | com.apple.spotlightserver    | ---- tryToPopQueue -> true : 145                                                                                                             |  13304
 D | mds          |                                | ImportServer  | com.apple.spotlightserver    | ---- tryToPopQueue -> true : 0                                                                                                               |  12385
 D | mds          |                                | ImportServer  | com.apple.spotlightserver    | ---- No minimum bank, or can't issue work:0x0                                                                                                |  12002
