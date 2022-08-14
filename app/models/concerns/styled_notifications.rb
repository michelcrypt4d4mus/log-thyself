module StyledNotifications
  extend ActiveSupport::Concern

  def say_and_log(msg, log_level: :info, styles: nil)
    if styles
      styles = [styles] unless styles.is_a?(Array)
      msg = Pastel.new.decorate(msg, *styles)
    end

    puts msg
    Rails.logger.public_send(log_level, msg)
  end
end
