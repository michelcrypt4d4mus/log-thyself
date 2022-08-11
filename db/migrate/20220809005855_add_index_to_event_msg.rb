# Special index for long strings: https://mazeez.dev/posts/pg-trgm-similarity-search-and-fast-like

class AddIndexToEventMsg < ActiveRecord::Migration[7.0]
  def up
    execute('CREATE EXTENSION IF NOT EXISTS pg_trgm')
    execute('CREATE INDEX index_msg_with_gin ON macos_system_logs USING gin (event_message gin_trgm_ops)')
  end
end
