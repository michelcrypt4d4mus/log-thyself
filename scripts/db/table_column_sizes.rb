colsizes = MacOsSystemLog.column_names.map { |c| "SUM(pg_column_size(#{c})) AS #{c} "}.join(",\n  ")
puts "SELECT\n  " + colsizes + "\nFROM macos_system_logs"
