thor collect:syslog:stream --level DEBUG &
thor collect:syslog:last 5m &

thor collect:old_log_system:load &
thor collect:old_log_system:stream &

sudo thor objectivesee:file_monitor:stream &
sudo thor objectivesee:process_monitor:stream &


# Find all .pklg files

