# Fix the order so we can use > and < on message_type

class FixMessageTypeEnum < ActiveRecord::Migration[7.0]
  MESSAGE_TYPES = %w[Debug Info Default Error Fault]

  def change
    drop_view :simplified_system_logs
    drop_function :msg_type_char
    create_enum :message_type, MESSAGE_TYPES

    execute("""
      ALTER TABLE macos_system_logs
        ALTER message_type TYPE message_type USING message_type::TEXT::message_type
    """)

    create_function :msg_type_char
    update_function :msg_type_char, version: 3
    create_view :simplified_system_logs
  end
end
