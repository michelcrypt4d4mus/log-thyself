class UpdateFunctionMsgTypeCharToVersion2 < ActiveRecord::Migration[7.0]
  def change
    drop_view :simplified_system_logs
    update_function :msg_type_char, version: 2, revert_to_version: 1
    create_view :simplified_system_logs
  end
end
