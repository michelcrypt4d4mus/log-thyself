class CreateLogfileLines < ActiveRecord::Migration[7.0]
  def change
    create_table :logfile_lines do |t|
      t.integer :logfile_id
      t.integer :line_number
      t.string :line
      t.timestamps
    end

    add_index :logfile_lines, %i(logfile_id line_number), unique: true
    add_index :logfile_lines, :line
  end
end
