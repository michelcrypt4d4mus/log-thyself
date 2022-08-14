-- Looks for events that are duplicated on given days
-- Helpful for finding spammy events

WITH daily_counts AS (
  SELECT
    TO_CHAR(log_timestamp, 'YY-MM-DD') AS "hour",
    msg_type_char(message_type, event_type) AS "L",
    process_name,
    sender_process_name,
    category,
    subsystem,
    event_message,
    COUNT(*) AS "count"
  FROM macos_system_logs
  GROUP BY 1,2,3,4,5,6,7
  ORDER BY 8 DESC
)

-- Just to make it easier to display
SELECT
  "hour",
  "L",
  LEFT(process_name, 25) AS process_name,
  LEFT(sender_process_name, 25) AS sender_process_name,
  LEFT(category, 15) AS category,
  LEFT(subsystem, 30) AS subsystem,
  LEFT(event_message, 90) AS msg,
  "count"
FROM daily_counts
