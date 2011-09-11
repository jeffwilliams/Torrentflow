#!/usr/bin/ruby
#
# This file is for running the torrent daemon. The torrent daemon
# uses mylibtorrent to run a libtorrent-rasterbar session. Clients
# can connect to the daemon to start and stop torrents, and to get 
# torrent status.
#

require 'syslog'
require 'OptionHandler'
require 'GenericTcpServer'
require 'GenericTcpMessageHandler'
require 'config'
require 'requesthandler'

$syslog = Syslog.open("torrentflow-daemon", Syslog::LOG_PID)

# Become a daemon.
def daemonize
  puts "daemonizing"
  
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

def handleSignal
  $syslog.info "Shutting down because of signal."
  exit 0
end

def printHelp
  puts "Usage: #{$0} [options]"
  puts "The torrentflow daemon."
  puts ""
  puts "Options: "
  puts "  -x:             Don't become a daemon; stay in the foreground"
  puts "  -p N, --port N: Listen on port N for clients."
end

$optDaemonize = true
$optPort = nil
# Parse options
def parseOptions
  opt = OptionHandler.new
  opt.parse

  if opt.opts.has_key?("h") || opt.opts.has_key?("help")
    printHelp
    exit 0
  end
  if opt.opts.has_key?("x")
    $optDaemonize = false
  end 
  if opt.opts.has_key?("p") || opt.opts.has_key?("port")
    val = nil
    val = opt.opts["p"].value if opt.opts.has_key?("p")
    val = opt.opts["port"].value if opt.opts.has_key?("port")
    optPort = val.to_i if val
  end
end

$config = Config.new
def parseConfig
  configPath = nil
  
  # Find config file
  configPath = Config::findConfigFile
  if ! configPath
    $syslog.info "Error: Can't locate config file #{Config::TorrentConfigFilename} in the current dir or in /etc."
    exit 1
  end

  if ! $config.load(configPath)
    exit 1
  end
end

# Load config file:
#   Storage directory
#   TCP Port to listen for start/stop clients
parseOptions
parseConfig

if $optPort
  $config.listenPort = $optPort
end

# Set umask so that group has write permission.
# This is so that mounted directories can be set up in such a way
# that the user the daemon is running as can belong to a group that has
# write permissions on the mount, even if it creates a directory that ends 
# up being owned by another user on that mount.
#
# For example, say you mount /mnt/data as a CIFS mount, using uid=www-data,gid=www-data
# and gave others on /mnt/data full perms. If a process run by user bob creates a directory
# it's user and group will be www-data after creation. If bob is in the group www-data
# he will only be able to create files in the directory if the directory has the group write
# perm set. This is controlled by umask.
#
File.umask(0002)

daemonize if $optDaemonize
$syslog.info "Started."

# Setup signal handlers
Signal.trap('SIGINT'){ 
  handleSignal
}
Signal.trap('SIGTERM'){ 
  handleSignal
}

genericServer = GenericTcpServer.new($config.listenPort, "0.0.0.0", false)

terminateRequestHandler = Proc.new{
  genericServer.stop 
}

begin
  requestHandler = RasterbarLibtorrentRequestHandler.new(terminateRequestHandler)
  genericServer.start( 
    Proc.new{ |clientSock, addr, port|
      #requestHandler = TestingRequestHandler.new(terminateRequestHandler)
      requestHandler.manage(clientSock, addr, port)
    }         
  ){ 
    $syslog.info "Listening on port #{$config.listenPort}."
  }
rescue
  $syslog.info "Got exception at top level: #{$!}"
  $syslog.info "#{$!.backtrace.join("  ")}"
end
