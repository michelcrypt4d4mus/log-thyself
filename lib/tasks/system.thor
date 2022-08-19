require 'etc'
require 'pastel'
require 'shared_methods'


module System
  class Daemon < Thor
    include SharedMethods

    EXAMPLE_PLIST = Dir[File.join(Rails.root, 'scripts/launchd/*.plist.example')].first
    DEFAULT_DAEMON_NAME = File.basename(EXAMPLE_PLIST).delete_suffix('.plist.example')

    class_option :daemon_name,
                  desc: 'Use your own possibly stealthier process name if you want (default is configurable in .env)',
                  default: ENV['DAEMON_NAME'].presence || DEFAULT_DAEMON_NAME

    desc 'install', 'Install as a launchd daemon (requires sudo)'
    option :launcher_script,
            desc: 'Script to use as the entry point',
            default: File.join(Rails.root, 'scripts/launch.sh')
    def install
      raise InvocationError.new("You don't have root privileges (maybe try again with sudo).") if Process.uid != 0

      daemon_name = options[:daemon_name]
      install_path = install_location(daemon_name)
      plist = Plist.parse_xml(EXAMPLE_PLIST)
      plist['Label'] = daemon_name

      plist['ProgramArguments'] = plist['ProgramArguments'].inject([]) do |args_list, arg|
        arg.gsub!('REPLACE_WITH_USERNAME', Etc.getlogin)
        arg.gsub!('REPLACE_THIS_WITH_PATH_TO_LAUNCH_SCRIPT', options[:launcher_script])
        args_list << arg
      end

      plist['EnvironmentVariables'] = plist['EnvironmentVariables'].inject({}) do |env_vars, (k, v)|
        env_vars[k] = v.gsub('REPLACE_WITH_USERNAME', Etc.getlogin)
        env_vars
      end

      %w[StandardOutPath StandardErrorPath].each do |stream|
        plist[stream] = plist[stream].sub('REPLACE_THIS_WITH_PATH_TO_LOGS', File.join(Rails.root, 'log'))
      end

      pastel = Pastel.new
      say(pastel.underline("\nLaunch Daemon Configuration\n"))
      say "#{plist.to_plist}\n", :green

      say(pastel.underline("\nWhat's Happening Here"))
      say("macOS uses .plist files to configure launch daemons (and a bunch of other")
      say("stuff). The configuration shown above will be the contents of the installed .plist.")
      say("It tells macOS to run the launcher (.#{options[:launcher_script].delete_prefix(Rails.root.to_s)}) when the system boots.")
      say(pastel.red.bold("\nNOTE: ") + "This will *only* launch the system log collector. Objective-See monitors\nmust be launched by hand.")
      say_key_value("\n#{pastel.underline('Installation Location')}", install_path)
      yes?("\nInstall?") ? true : exit
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

    def self.exit_on_failure?
      true
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
