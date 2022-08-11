class ConvertProcessIdToInt < ActiveRecord::Migration[7.0]
  def up
    alters = %i(process_id thread_id parent_activity_identifier).map do |col|
      "ALTER COLUMN #{col} TYPE INTEGER USING (#{col}::INTEGER)"
    end

    execute("ALTER TABLE macos_system_logs\n#{alters.join(",\n        ")}")

    %i(trace_id creator_activity_id).each do |col|
      change_column_comment :macos_system_logs, col, { from: nil, to: 'Max observed value was 20 digits' }
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
