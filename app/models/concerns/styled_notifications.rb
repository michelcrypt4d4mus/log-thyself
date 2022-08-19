module StyledNotifications
  extend ActiveSupport::Concern

  def say_and_log(msg, log_level: :info, styles: nil)
    pastel = Pastel.new

    if styles.blank?
      case log_level
      when :warn
        styles = :yellow
      when :error, :fatal
        styles = :red
      end
    end

    if styles.present?
      styles = [styles] unless styles.is_a?(Array)
      msg = pastel.decorate(msg, *styles)
    end

    puts msg if $stdout.tty?
    Rails.logger.public_send(log_level, msg)
  end
end
