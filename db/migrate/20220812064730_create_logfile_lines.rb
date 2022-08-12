class CreateLogfileLines < ActiveRecord::Migration[7.0]
  def change
    create_table :logfile_lines do |t|
      t.integer :logfile_id
      t.integer :line_number
      t.string :line
      t.timestamps
    end
  end
end
