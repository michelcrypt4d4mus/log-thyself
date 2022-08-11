# Enums save a lot of space

TYPE_ENUMS = {
  message_type: %w(
    Debug
    Default
    Error
    Fault
    Info
  ),
  event_type: %w(
    activityCreateEvent
    logEvent
    stateEvent
    timesyncEvent
  )
}

class ChangeMessageAndEventTypeColsToEnums < ActiveRecord::Migration[7.0]
  def up
    TYPE_ENUMS.each do |col, values|
      enum_type = "#{col}_enum"
      quoted_values = values.map{ |v| v.to_s.inspect }.join(', ').tr('"', "'")
      execute("CREATE TYPE #{enum_type} AS ENUM (#{quoted_values})")

      execute("""
        ALTER TABLE macos_system_logs
          ALTER COLUMN #{col}
          TYPE #{enum_type}
          USING #{col}::#{enum_type}
      """)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
