class CreateLogfileLines < ActiveRecord::Migration[7.0]
  def up
    create_table :logfile_lines do |t|
      t.integer :logfile_id, null: false
      t.integer :line_number, null: false
      t.string :line, null: false
      t.timestamps
    end

    add_index :logfile_lines, %i(logfile_id line_number), unique: true
    execute('CREATE INDEX index_line_with_gin ON logfile_lines USING gin (line gin_trgm_ops)')
  end

  def down
    drop_table :logfile_lines
  end
end
