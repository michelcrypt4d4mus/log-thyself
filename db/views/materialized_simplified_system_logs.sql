-- has a smashed col

CREATE TABLE materialized_simplified_system_logs AS (
SELECT
  id,
  log_timestamp,
  msg_type_char(message_type, event_type) AS "T",
  process_name,
  sender_process_name,
  category,
  subsystem,
  event_message,
  process_id,
  thread_id

  (process_name ||
      COALESCE(sender_process_name, '') ||
      COALESCE(category, '') ||
      COALESCE(subsystem, '') ||
      COALESCE(event_message, '')) AS search_string -- all cols of notes smashed together

FROM macos_system_logs
WHERE sender_process_name IS NULL
   OR sender_process_name <> 'BTAudioHALPlugin'
   OR message_type IS NULL
   OR message_type NOT IN ('Error', 'Default')
   OR id % 100 = 0 -- try to sample only a small subset of the ridic. amount of BTAudioHALPlugin debug and errors
);

-- COUNT
-- Seems to remove over half the rows overall (140M down to 63M)
SELECT
  -- id,
  -- log_timestamp,
  COUNT(*)
FROM macos_system_logs
WHERE sender_process_name IS NULL
   OR sender_process_name <> 'BTAudioHALPlugin'
   OR message_type IS NULL
   OR message_type NOT IN ('Error', 'Default')
   OR id % 100 = 0 -- try to sample only a small subset of the ridic. amount of BTAudioHALPlugin debug and errors


-- Inverse, so we can see what we'd be throwing out
SELECT
  msg_type_char(message_type, event_type) AS "T",
  process_name,
  sender_process_name,
  category,
  subsystem,
  event_message,
  COUNT(*)
FROM macos_system_logs
WHERE sender_process_name = 'BTAudioHALPlugin'
  AND message_type IN ('Error', 'Default')
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC;
