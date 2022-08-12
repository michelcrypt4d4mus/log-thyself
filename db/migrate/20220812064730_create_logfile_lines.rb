class CreateLogfileLines < ActiveRecord::Migration[7.0]
  def change
    create_table :logfile_lines do |t|

      t.timestamps
    end
  end
end
