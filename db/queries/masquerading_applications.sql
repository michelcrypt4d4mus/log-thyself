-- Looks for processes with the same name that are making system calls
-- from multiple paths

-- Processes
WITH processes AS (
  SELECT DISTINCT
    process_name,
    process_image_path
  FROM macos_system_logs
  WHERE process_image_path IS NOT NULL -- Avoid logs captured the old way in syslog format
),

multi_source_processes AS (
  SELECT
    process_name,
    COUNT(*) AS unique_image_count
  FROM processes
  GROUP BY 1
  HAVING COUNT(*) > 1
)

SELECT
  macos_system_logs.process_name,
  macos_system_logs.process_image_path,
  multi_source_processes.unique_image_count,
  COUNT(*) AS event_count
FROM macos_system_logs
  INNER JOIN multi_source_processes
          ON multi_source_processes.process_name = macos_system_logs.process_name
GROUP BY 1,2,3
ORDER BY 1,2,3


-- Sender processes
WITH senders AS (
  SELECT
    sender_process_name,
    sender_image_path,
    COUNT(*) AS event_count
  FROM macos_system_logs
  WHERE log_timestamp > '2022-08-08 09:00:00'
  GROUP BY 1,2
),

multi_senders AS (
  SELECT
    sender_process_name,
    COUNT(*) AS unique_source_image_count
  FROM senders
  GROUP BY 1
  HAVING COUNT(*) > 1
)

SELECT
  multi_senders.sender_process_name,
  sender_image_path,
  unique_source_image_count
FROM macos_system_logs
  INNER JOIN multi_senders
          ON multi_senders.sender_process_name = macos_system_logs.sender_process_name
GROUP BY 1,2,3
ORDER BY 3,1,2