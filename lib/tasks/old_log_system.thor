module Collect
  class OldLogSystem < Thor
    desc 'load', "Load all extant old logging system files"
    option :continue_streaming,
            desc: 'Continue loading new lines from active logs once extant logs are loaded',
            type: :boolean,
            default: false
    def load
      Logfile.write_closed_logfile_contents_to_db!
    end

    desc 'stream', "Stream logs from the new filesystem (mostly the ones seen in Console.app)"
    def stream
      LogFileWatcher.new.load_and_stream!
    end
  end
end
