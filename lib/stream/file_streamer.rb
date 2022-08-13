# Convenience class for when you want the shell_command to be 'cat FILE'

class FileStreamer < ShellCommandStreamer
  def initialize(file)
    super("cat \"#{file}\"")
  end
end
