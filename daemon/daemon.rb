#!/usr/bin/ruby
#
# This file is for running the torrent daemon. The torrent daemon
# uses mylibtorrent to run a libtorrent-rasterbar session. Clients
# can connect to the daemon to start and stop torrents, and to get 
# torrent status.
#

# Setup the load path
if ! File.directory?("daemon")
  $stderr.puts "The daemon directory cannot be found. Make sure to run this script from the base installation directory, as 'daemon/daemon.rb'"
  exit 1
end
if ! $:.include?("daemon")
  $: << "daemon"
end
if ! $:.include?(".")
  $: << "."
end

require 'logging'
require 'OptionHandler'
require 'GenericTcpServer'
require 'GenericTcpMessageHandler'
require 'config'
require 'requesthandler'
require 'TestingRequestHandler'
require 'util'

# Default logfile
Logfile = "logs/daemon.log"

def handleSignal
  $logger.info "Shutting down because of signal."
  exit 0
end

def printHelp
  puts "Usage: #{$0} [options]"
  puts "The torrentflow daemon."
  puts ""
  puts "Options: "
  puts "  -h, --help:     Show this help"
  puts "  -x:             Don't become a daemon; stay in the foreground"
  puts "  -p N, --port N: Listen on port N for clients."
  puts "  -l X, --facility X:  Syslog facility to use. Valid values are (case insensitive):"
  puts "                LOG_AUTH, LOG_AUTHPRIV, LOG_CRON, LOG_DAEMON, LOG_FTP, LOG_KERN"
  puts "                LOG_LOCAL0 through LOG_LOCAL7, LOG_LPR, LOG_MAIL, LOG_NEWS, LOG_SYSLOG"
  puts "                LOG_USER (default), LOG_UUCP"
end

$optDaemonize = true
$optPort = nil

# Set up initial logger
$logger = makeFileLogger(Logfile, 5, 5000000)

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
    $optPort = val.to_i if val
  end
  
  if opt.opts.has_key?("l") || opt.opts.has_key?("facility")
    val = nil
    val = opt.opts["l"].value if opt.opts.has_key?("l")
    val = opt.opts["facility"].value if opt.opts.has_key?("facility")
    SyslogWrapper.setFacility(val) if val
  end

end

$config = TorrentflowConfig.new
def parseConfig
  configPath = nil
  
  # Find config file
  configPath = TorrentflowConfig::findConfigFile
  if ! configPath
    $logger.error "Can't locate config file #{TorrentflowConfig::TorrentConfigFilename}."
    exit 1
  end

  if ! $config.load(configPath)
    exit 1
  end
end

# Parse options and load config file.
parseOptions
parseConfig

# If the user specified a port as an option, override the config file setting.
if $optPort
  $config.listenPort = $optPort
end

# Adjust logger based on configuration settings
if ( $config.logType == :file )
  $logger = makeFileLogger($config.logFile, $config.logCount, $config.logSize)
  $logger.level = $config.logLevel
else
  $logger = makeSyslogLogger("torrentflow-daemon", $config.logFacility)
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
$logger.info "Started."

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
  $logger.debug "Creating RasterbarLibtorrentRequestHandler..."
  requestHandler = RasterbarLibtorrentRequestHandler.new(terminateRequestHandler)
  #requestHandler = TestingRequestHandler.new(terminateRequestHandler)
  genericServer.start( 
    Proc.new{ |clientSock, addr, port|
      requestHandler.manage(clientSock, addr, port)
    }         
  ){ 
    $logger.info "Listening on port #{$config.listenPort}."
  }
rescue
  $logger.error "Got exception at top level: #{$!}"
  $logger.error "#{$!.backtrace.join("  ")}"
end
