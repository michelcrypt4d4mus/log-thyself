SELECT *
FROM simplified_system_logs
WHERE sender_process_name ~* 'VoiceShortCuts'
   OR process_name ~* 'siriactionsd|Shortcut'
   OR event_message ~ 'VCCKShortcutSyncService'
ORDER BY log_timestamp DESC
