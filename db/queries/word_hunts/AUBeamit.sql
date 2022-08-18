 SELECT
   id,
   msg_type_char(message_type, event_type)  AS "L",
   log_timestamp,
   RIGHT(process_name, 40) AS process_name,
   RIGHT(sender_process_name, 30) AS sender,
   LEFT("category", 25) AS "category",
   RIGHT(subsystem, 40) AS subsystem,
   event_message,
   process_id
 FROM macos_system_logs
 WHERE (
        COALESCE(process_name, '')
     || COALESCE(sender_process_name, '')
     || COALESCE(category, '')
     || COALESCE(subsystem, '')
     || COALESCE(event_message, '')
    ) ~* 'beamit'
 ORDER BY 3 DESC
 ;
