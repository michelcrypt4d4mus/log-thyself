
CREATE FUNCTION
  redact_ids(a_string VARCHAR)
  RETURNS VARCHAR
AS $$
  SELECT
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        REGEXP_REPLACE(
          REGEXP_REPLACE($1, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}', '[redacted UUID]'),
          '0x[0-9A-Fa-f]+|[0-9A-Fa-f]{6,}', '[redacted hex]'
        ),
        'Hostname#[0-9a-f]+:\d+', '[redacted host]'
      ),
      '\d{3}-\d{3}-\D{4}', '[redacted ID]'
    )

$$
LANGUAGE SQL
IMMUTABLE
LEAKPROOF
PARALLEL SAFE
