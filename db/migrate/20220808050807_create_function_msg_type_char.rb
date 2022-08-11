class CreateFunctionMsgTypeChar < ActiveRecord::Migration[7.0]
  def change
    create_function :msg_type_char
  end
end
