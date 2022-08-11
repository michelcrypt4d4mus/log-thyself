-- Function creates a single character coding unifying message and event
-- type cols based on the fact that message_type is only set for
-- event_type of "logEvent"
--
-- MESSAGE_TYPES (uppercase):
--    Default                 => _
--    Debug                   => D
--    Info                    => I
--    Error                   => E
--    Fault                   => F
--
-- EVEMT_TYPES (lowercase):
--    activityCreateEvent     => a
--    activityTransitionEvent => c
--    timesyncEvent           => t
--    stateEvent              => s
--    signpostEvent           => p
--    traceEvent              => r
--    userActionEvent         => u
--
-- EVERYTHING ELSE            => ?


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
        THEN 'I'
      WHEN $1 = 'Default'
        THEN '_'
      WHEN $2 = 'activityCreateEvent'
        THEN 'a'
      WHEN $1 = 'Error'
        THEN 'E'
      WHEN $1 = 'Fault'
        THEN 'F'
      WHEN $2 = 'stateEvent'
        THEN 's'
      WHEN $2 = 'timesyncEvent'
        THEN 't'
      WHEN $2 = 'activityTransitionEvent'
        THEN 'c'
      WHEN $2 = 'signpostEvent'
        THEN 'p'
      WHEN $2 = 'traceEvent'
        THEN 'r'
      WHEN $2 = 'userActionEvent'
        THEN 'u'
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