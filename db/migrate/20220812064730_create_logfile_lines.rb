class CreateLogfileLines < ActiveRecord::Migration[7.0]
  def change
    create_table :logfile_lines do |t|
      t.integer :logfile_id, null: false
      t.integer :line_number, null: false
      t.string :line, null: false
      t.timestamps
    end

    add_index :logfile_lines, %i(logfile_id line_number), unique: true
    add_index :logfile_lines, :line
  end
end
