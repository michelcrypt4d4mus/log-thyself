class UpdateSimplifiedSystemLogsToVersion2 < ActiveRecord::Migration[7.0]
  def change
    update_view :simplified_system_logs, version: 2, revert_to_version: 1
  end
end
