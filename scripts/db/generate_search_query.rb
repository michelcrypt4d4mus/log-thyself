#!/usr/bin/env ruby
# Generate a query that checks a bunch of fields for a case insensitive substring
# Useful for tracking down leads.

search_term = "'#{ARGV[0]}'"

sql = <<-SQL
    SELECT
        LEFT(message_type, 1) AS "t",
        LEFT(process_name, 20) AS process_name,
        LEFT(sender_process_name, 17) AS sender,
        LEFT("category", 23) AS "category",
        LEFT(subsystem, 25) AS subsystem,
        LEFT(event_message, 81) AS msg,
        COUNT(*)
    FROM simplified_system_logs
    WHERE process_name ILIKE #{search_term}
       OR sender_process_name ILIKE #{search_term}
       OR category ILIKE #{search_term}
       OR subsystem ILIKE #{search_term}
       OR event_message ILIKE #{search_term}
    GROUP BY 1,2,3,4,5,6
    ORDER BY 7 DESC;
SQL

puts sql

