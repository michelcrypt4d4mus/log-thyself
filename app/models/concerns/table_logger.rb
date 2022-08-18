module TableLogger
  extend ActiveSupport::Concern

  # If we don't force the daemon to render with a width it will verticalize the table
  # I suspect it computes a width of 0 because of the lack of TTY
  DAEMON_TABLE_RENDER_OPTIONS = { width: 120, resize: true }

  def table_render_options
    @table_render_options = Rails.env.production? ? DAEMON_TABLE_RENDER_OPTIONS : {}
  end
end
