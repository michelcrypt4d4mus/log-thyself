require 'etc'
require 'shared_methods'


module System
  class Daemon < Thor
    include SharedMethods

    EXAMPLE_PLIST = Dir[File.join(Rails.root, 'scripts/launchd/*.plist.example')].first
    DEFAULT_DAEMON_NAME = File.basename(EXAMPLE_PLIST).delete_suffix('.plist.example')

    class_option :daemon_name,
                  desc: 'Use your own possibly stealthier process name if you want (default is configurable in .env)',
                  default: ENV['DAEMON_NAME'] || DEFAULT_DAEMON_NAME

    desc 'install', 'Install as a launchd daemon (requires sudo)'
    option :launcher_script,
            desc: 'Script to use as the entry point',
            default: File.join(Rails.root, 'scripts/start_log_stream_loader.sh')
    def install
      raise "You don't have root privileges. Maybe try again with sudo." if Process.uid != 0

      daemon_name = options[:daemon_name]
      install_path = install_location(daemon_name)
      plist = Plist.parse_xml(File.join(Rails.root, "scripts/launchd/#{DEFAULT_DAEMON_NAME}.plist.example"))
      plist['Label'] = daemon_name

      plist['ProgramArguments'] = plist['ProgramArguments'].inject([]) do |args_list, arg|
        next (args_list << Etc.getlogin) if arg == 'REPLACE_WITH_USERNAME'
        next (args_list << options[:launcher_script]) if arg == 'REPLACE_THIS_WITH_PATH_TO_LAUNCH_SCRIPT'
        args_list << arg
      end

      config_message = 'Configuration'
      say "\n#{config_message}\n#{'‾' * config_message.length}"
      say "#{plist.to_plist}\n", :green

      say("Daemons begin as root. This one will sudo down a notch to your account to actually run the log collector.")
      say("This is necessary because root doesn't have all the prerequisites set up but also good because it means the code is not executing with root privileges.\n")
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

    desc 'stop', "Stop the daemon (it may return when you reboot unless you :disable or :uninstall it)"
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

    desc 'uninstall', "Uninstall the daemon (:enable will be run to purge it it even from the dissabled list)"
    def uninstall
      invoke :stop
      invoke :enable
      execute_shell_command("rm #{install_location(options[:daemon_name])}")
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
