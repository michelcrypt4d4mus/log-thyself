colsizes = MacOsSystemLog.column_names.map do |c|
  "ROUND(SUM(pg_column_size(#{c})) / #{1.megabyte}) AS #{c} "
end
puts "SELECT\n  " + colsizes.join(",\n  ") + "\nFROM macos_system_logs"

# macos_system_logs
SELECT
  ROUND(SUM(pg_column_size(id)) / 1048576) AS id ,
  ROUND(SUM(pg_column_size(log_timestamp)) / 1048576) AS log_timestamp ,
  ROUND(SUM(pg_column_size(event_type)) / 1048576) AS event_type ,
  ROUND(SUM(pg_column_size(message_type)) / 1048576) AS message_type ,
  ROUND(SUM(pg_column_size(category)) / 1048576) AS category ,
  ROUND(SUM(pg_column_size(event_message)) / 1048576) AS event_message ,
  ROUND(SUM(pg_column_size(process_name)) / 1048576) AS process_name ,
  ROUND(SUM(pg_column_size(sender_process_name)) / 1048576) AS sender_process_name ,
  ROUND(SUM(pg_column_size(subsystem)) / 1048576) AS subsystem ,
  ROUND(SUM(pg_column_size(process_id)) / 1048576) AS process_id ,
  ROUND(SUM(pg_column_size(thread_id)) / 1048576) AS thread_id ,
  ROUND(SUM(pg_column_size(trace_id)) / 1048576) AS trace_id ,
  ROUND(SUM(pg_column_size(source)) / 1048576) AS source ,
  ROUND(SUM(pg_column_size(activity_identifier)) / 1048576) AS activity_identifier ,
  ROUND(SUM(pg_column_size(parent_activity_identifier)) / 1048576) AS parent_activity_identifier ,
  ROUND(SUM(pg_column_size(backtrace)) / 1048576) AS backtrace ,
  ROUND(SUM(pg_column_size(process_image_path)) / 1048576) AS process_image_path ,
  ROUND(SUM(pg_column_size(sender_image_path)) / 1048576) AS sender_image_path ,
  ROUND(SUM(pg_column_size(boot_uuid)) / 1048576) AS boot_uuid ,
  ROUND(SUM(pg_column_size(process_image_uuid)) / 1048576) AS process_image_uuid ,
  ROUND(SUM(pg_column_size(sender_image_uuid)) / 1048576) AS sender_image_uuid ,
  ROUND(SUM(pg_column_size(mach_timestamp)) / 1048576) AS mach_timestamp ,
  ROUND(SUM(pg_column_size(sender_program_counter)) / 1048576) AS sender_program_counter ,
  ROUND(SUM(pg_column_size(timezone_name)) / 1048576) AS timezone_name ,
  ROUND(SUM(pg_column_size(creator_activity_id)) / 1048576) AS creator_activity_id ,
  ROUND(SUM(pg_column_size(created_at)) / 1048576) AS created_at
FROM macos_system_logs
