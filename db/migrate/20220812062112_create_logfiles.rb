class CreateLogfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :logfiles do |t|
      t.string :file_path
      t.timestamps
    end
  end
end
