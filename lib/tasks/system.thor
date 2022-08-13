require 'etc'
require 'shared_methods'


module System
  class Daemon < Thor
    include SharedMethods

    class_option :daemon_name,
                  desc: 'Use your own, possibly stealthier, process name (default is configurable in .env)',
                  default: ENV['DAEMON_NAME'] || 'cryptadamus.logloader'

    desc 'install', 'Install as a launchd daemon (requires sudo)'
    option :launcher_script,
            desc: 'Script to use as the entry point',
            default: File.join(Rails.root, 'scripts/start_log_stream_loader.sh')
    def install
      raise "You don't have root privileges. Maybe try again with sudo." if Process.uid != 0

      daemon_name = options[:daemon_name]
      install_path = install_location(daemon_name)
      plist = Plist.parse_xml(File.join(Rails.root, 'scripts/launchd/cryptadamus.logloader.plist.example'))
      plist['Label'] = daemon_name

      plist['ProgramArguments'] = plist['ProgramArguments'].inject([]) do |args_list, arg|
        next (args_list << Etc.getlogin) if arg == 'REPLACE_WITH_USERNAME'
        next (args_list << options[:launcher_script]) if arg == 'REPLACE_THIS_WITH_PATH_TO_LAUNCH_SCRIPT'
        args_list << arg
      end

      config_message = 'Configuration that will be installed'
      say "\n#{config_message}\n#{'‾' * config_message.length}"
      say "#{plist.to_plist}\n", :green

      say_key_value("Destination", install_path)
      yes?('Install?') ? true : exit
      plist.save_plist(install_path)
      say "Wrote configuration. Launching..."
      invoke :start
    end

    desc 'start', 'Start the daemon'
    def start
      execute_shell_command("launchctl bootstrap system #{install_location(options[:daemon_name])}")
    end

    desc 'stop', "Stop the daemon. It may come back next time you reboot unless you :disable it"
    def stop
      execute_shell_command("launchctl bootout system/#{options[:daemon_name]}")
    end

    desc 'disable', "Disable the daemon permanently"
    def disable
      execute_shell_command("launchctl disable system/#{options[:daemon_name]}")
    end

    desc 'enable', "Enable the daemon"
    def enable
      execute_shell_command("launchctl enable system/#{options[:daemon_name]}")
    end

    desc 'status', "See what the launchd manager thinks abouut your daemon"
    def status
      execute_shell_command("launchctl print system/#{options[:daemon_name]}")
    end

    no_commands do
      def install_location(daemon_name)
        "/Library/LaunchDaemons/#{daemon_name}.plist"
      end

      def execute_shell_command(cmd)
        say_key_value('Executing', cmd)

        if (return_value = `#{cmd} 2>&1`).blank?
          say 'Done.'
        else
          say "\nDone. Execution returned this:\n"
          say return_value, :yellow
        end

        return_value
      end
    end
  end
end
