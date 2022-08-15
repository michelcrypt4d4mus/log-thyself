class CollecTHOR < Thor
  include StyledNotifications

  # TODO collect:old_log_system:stream
  # objectivesee:process_monitor:stream
  INVOCABLE_COLLECTORS = %w[
    collect:syslog:stream
    objectivesee:file_monitor:stream
  ]

  desc 'collect_all', '[EXPERIMENTAL] Collect all the things in forked processes'
  def collect_all
    args_to_pass = ARGV.length > 1 ? ARGV[1..-1] : nil

    INVOCABLE_COLLECTORS.each do |invocable|
      say_and_log("Invoking #{invocable}...", styles: [:cyan])
      pid = Process.spawn("thor #{invocable}", *args_to_pass)
      say_and_log("Now running with pid #{pid}, detaching...")
      Process.detach(pid)
    end

    say_and_log("Detached, jumping into the ocean...")
  end
end
