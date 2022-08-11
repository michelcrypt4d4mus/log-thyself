-- Ran around 12:15AM 2022-08-11
-- DELETE 1572777
DELETE FROM macos_system_logs
WHERE event_message LIKE '%PasswordInputOnlyAllowsRomanLocale%'
  AND id % 100 <> 1;

