
CREATE FUNCTION
  redact_ids(a_string VARCHAR)
  RETURNS VARCHAR
AS $$
  SELECT
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE($1, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '[redacted UUID]'),
        '0x[0-9A-Fa-f]+', '[redacted hex]'
      ),
      'Hostname#[0-9a-f]+:\d+', '[redacted host]'
    )

$$
LANGUAGE SQL
IMMUTABLE
LEAKPROOF
PARALLEL SAFE
