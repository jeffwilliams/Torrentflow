
# Become a daemon.
def daemonize
  rc = fork
  if rc.nil?
    # Child!
    Process.setsid
    # Chdir so that the OS can unmount the directory we were in.
    #Dir.chdir "/"

    # Close stdin, stdout, stderr, (and reopen?).
    $stdin.close
    $stdout.close
    $stderr.close
    $stdin = File.open("/dev/null","w+")
    $stdout = File.open("/dev/null","w+")
    $stderr = File.open("/dev/null","w+")

  elsif rc < 0 
    $stderr.puts "Fork failed. Aborting."
    exit 1
  else rc
    # Parent. Just exit.
    Process.detach rc
    exit 0
  end
end
