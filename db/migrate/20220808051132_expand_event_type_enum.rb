class ExpandEventTypeEnum < ActiveRecord::Migration[7.0]
  NEW_EVENT_TYPES = %w(
    activityTransitionEvent
    signpostEvent
    traceEvent
    userActionEvent
  )

  def up
    NEW_EVENT_TYPES.each do |event_type|
      execute("ALTER TYPE event_type_enum ADD VALUE '#{event_type}'")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
