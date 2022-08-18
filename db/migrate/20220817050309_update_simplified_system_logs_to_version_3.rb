class UpdateSimplifiedSystemLogsToVersion3 < ActiveRecord::Migration[7.0]
  def change
    update_view :simplified_system_logs, version: 3, revert_to_version: 2
  end
end
