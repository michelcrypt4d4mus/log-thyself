class Callthecollecthor < Thor
  include StyledNotifications

  class_option :launch_as_zombies,
                desc: "Start as zombified background process(es) (will require 'kill PID' to stop)",
                type: :boolean,
                default: false

  # These can be safely launched by the daemon process, unlike the Objective-See apps
  # See: https://developer.apple.com/documentation/xcode/signing-a-daemon-with-a-restricted-entitlement
  DAEMON_STREAMS = %w[
    collect:consolelogs:stream
    collect:syslog:stream
  ]

  OBJECTIVE_SEE_STREAMS = %w[
    objectivesee:file_monitor:stream
    objectivesee:process_monitor:stream
  ]

  PAST_SCANS = %w[
    collect:syslog:last 365d
    collect:consolelogs:load
  ]

  FUTURE_STREAMS = DAEMON_STREAMS + OBJECTIVE_SEE_STREAMS

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

  desc 'daemon', 'System logs, both old and new (but not Objective-See monitors)'
  def daemon
    start_em_up(DAEMON_STREAMS)
  end

  desc 'objectivesee', 'Launch the Objective-See monitors (requires sudo)'
  def objectivesee
    start_em_up(OBJECTIVE_SEE_STREAMS)
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
