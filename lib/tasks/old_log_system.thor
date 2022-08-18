# TODO: rename file

module Collect
  class Consolelogs < CommonCommand
    desc 'load', "Load old/deprecated logging system files (the ones you see in Console.app) from their customary locations"
    option :continue,
            desc: 'Continue loading new lines from active logs',
            type: :boolean,
            default: false
    def load
      Logfile.write_closed_logfile_contents_to_db!
      LogFileWatcher.load_and_stream_all_open_logfiles! if options[:continue]
    end

    desc 'load_dir DIR', "Load all files in directory DIR. They don't even have to be log files. Will unzip and process many compressed formats as well as wireshark/bluetooth/tcpdump packet captures files."
    option :include_subdirs,
            desc: 'Recursively include subdirectories',
            type: :boolean,
            default: true
    def load_dir(directory)
      Logfile.load_all_files_in_directory!(directory, options)
    end

    desc 'stream', "Stream old logs from the filesystem (mostly the ones seen in Console.app)"
    def stream
      LogFileWatcher.load_and_stream_all_open_logfiles!
    end
  end
end
