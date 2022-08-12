class CreateLogfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :logfiles do |t|
      t.string :file_path
      t.datetime :file_created_at
      t.timestamps
    end

    add_index :logfiles, %i(file_path file_created_at), unique: true
  end
end
