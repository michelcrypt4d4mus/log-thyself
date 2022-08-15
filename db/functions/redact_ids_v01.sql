
CREATE FUNCTION
  redact_ids(a_string VARCHAR)
  RETURNS VARCHAR
AS $$
  SELECT
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE($1, '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', '[redacted UUID]', 'ig'),
            '0x[0-9a-f]+|[0-9a-f]{6,}', '[redacted hex]', 'ig'
          ),
          'Hostname#[0-9a-f]+:\d+', '[redacted host]', 'ig'
        ),
        '\d{3}-\d{3}-\d{3,}', '[redacted ID]', 'ig'
      ),
      'pid[=: ]{0,2}\d+', '[redacted PID]', 'ig'
    )

$$
LANGUAGE SQL
IMMUTABLE
LEAKPROOF
PARALLEL SAFE
