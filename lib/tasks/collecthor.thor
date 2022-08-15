class CollecTHOR < Thor
  desc 'collect_all', 'Collect all the things in forked processes'
  def collect_all
    Process.detach(fork { invoke 'collect:syslog:stream' })
    Process.detach(fork { invoke 'objectivesee:file_monitor:stream' })
    Process.detach(fork { invoke 'objectivesee:process_monitor:stream' })
    # TODO collect:old_log_system:stream
  end
end
