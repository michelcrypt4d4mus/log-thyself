class Callthecollecthor < Thor
  include StyledNotifications

  class_option :launch_as_zombies,
                desc: "Start as zombified background process(es) (will require 'kill PID' to stop)",
                type: :boolean,
                default: false

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
      pids = invocables.map do |invocable|
        say_and_log("Invoking #{invocable}...", styles: [:cyan])
        Process.spawn("thor #{invocable}")
      end

      if options[:launch_as_zombies]
        pids.each { |pid| Process.detach(pid) }
        say_and_log("Successfully zombified (run 'kill #{pids.join (' ')}' to stop)", styles: [:green])
        say_and_log("Detached, jumping into the ocean...", styles: [:cyan])
      else
        pids.each { |pid| Process.wait(pid) }
        say_and_log("Waiting for child processes (#{pids.join(', ')})")
      end
    end
  end
end
