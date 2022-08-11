-- bluetooth stuff
SELECT
  msg_type_char(message_type, event_type) AS "L",
  LEFT(process_name, 20) AS process_name,
  LEFT(sender_process_name, 17) AS sender,
  LEFT("category", 23) AS "category",
  LEFT(subsystem, 25) AS subsystem,
  LEFT(event_message, 81) AS msg,
  COUNT(*)
FROM macos_system_logs
WHERE sender_process_name LIKE '%BT%'
   OR sender_process_name ILIKE '%blue%'
   OR process_name LIKE '%BT%'
   OR process_name ILIKE '%blue%'
   OR event_message LIKE '%BT%'
   OR event_message ILIKE '%blue%'
   OR "category" LIKE '%BT%'
   OR "category" ILIKE '%blue%'
   OR subsystem LIKE '%BT%'
   OR subsystem ILIKE '%blue%'
group by 1,2,3,4,5,6 order by 7 DESC;


-- Auth related
SELECT
  message_type,
  LEFT(process_name, 30) AS process_name,
  "category",
  LEFT(subsystem, 35) AS subsystem,
  LEFT(event_message, 100) AS msg,
  COUNT(*)
from macos_system_logs
WHERE sender_process_name ILIKE '%auth%'
   OR process_name ILIKE '%auth%'
   OR event_message ILIKE '%auth%'
group by 1,2,3,4,5 order by 6 desc;


-- Errors/faults
SELECT
  msg_type_char(message_type, event_type) AS "L",
  LEFT(process_name, 20) AS process_name,
  LEFT(sender_process_name, 20) AS sender_name,
  LEFT("category", '15') AS "category",
  LEFT(subsystem, 30) AS subsystem,
  LEFT(event_message, 75) AS msg,
  COUNT(*)
FROM macos_system_logs
WHERE message_type IN ('Error', 'Fault')
group by 1,2,3,4,5,6 order by 7 desc;


-- Faults
SELECT
  msg_type_char(message_type, event_type) AS "L",
  LEFT(process_name, 20) AS process_name,
  LEFT(sender_process_name, 20) AS sender_name,
  LEFT("category", '15') AS "category",
  LEFT(subsystem, 30) AS subsystem,
  LEFT(event_message, 75) AS msg,
  COUNT(*)
FROM macos_system_logs
WHERE message_type = 'Fault'
  AND event_message NOT LIKE '%This will become an error in the future%'
  AND event_message NOT LIKE '%This will be disallowed in the future%'
group by 1,2,3,4,5,6 order by 7 desc;



-- Recent faults
SELECT *
FROM macos_system_logs
WHERE message_type = 'Fault'
ORDER BY log_timestamp DESC;


-- message/event type counts
select
  message_type,
  event_type,
  msg_type_char(message_type, event_type) AS msg_type_char
  count(*)
FROM macos_system_logs
group by 1,2,3 order by 4 desc;


-- VICEROY!!!
-- DCP event counts (DCP is kinda sus)
-- TeaFoundation
select * FROM macos_system_logs where sender_process_name ILIKE '%TeaFoundation%' OR process_name ILIKE '%TeaFoundation%' OR "category" ILIKE '%TeaFoundation%' OR event_message ILIKE '%TeaFoundation%' or subsystem ILIKE '%TeaFoundation%';
