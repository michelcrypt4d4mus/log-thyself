class CollectHOR < Thor
  include StyledNotifications

  MOST_INVOCABLES = %w[
    collect:syslog:stream
    objectivesee:file_monitor:stream
    objectivesee:process_monitor:stream
  ]

  # TODO collect:old_log_system:stream
  INVOCABLE_COLLECTORS = MOST_INVOCABLES + %w[
    collect:old_log_system:load
    collect:old_log_system:stream
  ]

  desc 'collect_all', '[EXPERIMENTAL] Collect all the things in forked processes'
  def collect_all
    start_em_up(INVOCABLE_COLLECTORS)
  end

  desc 'collect_most', 'System Logs, FileMonitor, ProcessMonitor (requires sudo!)'
  def collect_most
    start_em_up(MOST_INVOCABLES)
  end

  no_commands do
    def start_em_up(invocables, args_to_pass: nil)
      args_to_pass = ARGV.length > 1 ? ARGV[1..-1] : []

      invocables.each do |invocable|
        puts "inv: #{invocable}"
        puts "args: #{args_to_pass}"
        args = ["thor #{invocable}"] + args_to_pass
        say_and_log("Invoking #{invocable}...", styles: [:cyan])
        pid = Process.spawn(*args)
        say_and_log("#{invocable} now running with pid #{pid}, detaching...")
        Process.detach(pid)
      end

      say_and_log("Detached, jumping into the ocean...", styles: [:cyan])
    end
  end
end
