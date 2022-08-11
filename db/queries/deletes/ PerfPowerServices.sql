DELETE FROM macos_system_logs
WHERE process_name = 'PerfPowerServices'
  AND id % 100 <> 1;
