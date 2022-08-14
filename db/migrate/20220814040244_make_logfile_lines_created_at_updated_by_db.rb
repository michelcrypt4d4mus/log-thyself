class MakeLogfileLinesCreatedAtUpdatedByDb < ActiveRecord::Migration[7.0]
  def change
    remove_column :logfile_lines, :updated_at
    remove_column :logfile_lines, :created_at

    execute("""
      ALTER TABLE logfile_lines
        ADD COLUMN created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc')
    """)
  end
end
