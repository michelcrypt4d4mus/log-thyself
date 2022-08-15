class Callthecollecthor < Thor
  include StyledNotifications

  FUTURE_STREAMS = %w[
    collect:syslog:stream
    objectivesee:file_monitor:stream
    objectivesee:process_monitor:stream
  ]

  PAST_SCANS = [
    'collect:syslog:last 365d',
    'collect:consolelogs:load',
    'collect:consolelogs:stream',
  ]

  desc 'everything', 'Collect all the things (future and past) in forked processes'
  def everything
    start_em_up(PAST_SCANS)
    start_em_up(FUTURE_STREAMS)
  end

  desc 'future', 'System Logs, FileMonitor, ProcessMonitor from now (requires sudo!)'
  def future
    start_em_up(FUTURE_STREAMS)
  end

  desc 'past', 'System logs from the pass, Console.app text, ASL logs, tcp/bluetooth capture files'
  def past
    start_em_up(PAST_SCANS)
  end

  no_commands do
    def start_em_up(invocables)
      invocables.each do |invocable|
        say_and_log("Invoking #{invocable}...", styles: [:cyan])
        pid = Process.spawn("thor #{invocable}")
        say_and_log("#{invocable} now running with pid #{pid}, detaching...")
        Process.detach(pid)
      end

      say_and_log("Detached, jumping into the ocean...", styles: [:cyan])
    end
  end
end
