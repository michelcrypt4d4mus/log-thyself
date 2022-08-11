-- Ran around 1am 2022-08-11 (deleted 5,167,625 rows)
DELETE FROM macos_system_logs
WHERE process_name = 'powerd'
  AND id % 100 <> 1;
