class CreateSimplifiedSystemLogs < ActiveRecord::Migration[7.0]
  def change
    create_view :simplified_system_logs
  end
end
