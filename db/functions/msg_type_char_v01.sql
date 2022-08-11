-- Function creates a single character coding unifying message and event
-- type cols based on the fact that message_type is only set for
-- event_type of "logEvent"
--
-- MESSAGE_TYPES:
--    Default             => d
--    Debug               => D
--    Info                => I
--    Error               => E
--    Fault               => F
--
-- EVEMT_TYPES:
--    activityCreateEvent => A
--    timesyncEvent       => T
--    stateEvent          => S
--
-- EVERYTHING ELSE        => ?


CREATE FUNCTION
  msg_type_char(message_type message_type_enum, event_type event_type_enum)
  RETURNS CHAR
AS $$
  SELECT
    -- Most to least frequent for speed reasons
    CASE
      WHEN $1 = 'Debug'
        THEN 'D'
      WHEN $1 = 'Info'
        THEN 'D'
      WHEN $1 = 'Default'
        THEN 'd'
      WHEN $2 = 'activityCreateEvent'
        THEN 'A'
      WHEN $1 = 'Error'
        THEN 'E'
      WHEN $1 = 'Fault'
        THEN 'F'
      WHEN $2 = 'stateEvent'
        THEN 'S'
      WHEN $2 = 'timesyncEvent'
        THEN 'T'
      WHEN $1 IS NULL AND $2 IS NULL
        THEN NULL
      ELSE
        '?'
      END
$$
LANGUAGE SQL
CALLED ON NULL INPUT
IMMUTABLE
LEAKPROOF
PARALLEL SAFE