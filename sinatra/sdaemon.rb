#!/usr/bin/env ruby

# Setup the load path
if ! File.directory?("www-lib")
  $stderr.puts "The www-lib directory cannot be found. Make sure to run this script from the base installation directory, as 'sinatra/server.rb'"
  exit 1
end
if ! $:.include?("www-lib")
  $: << "www-lib"
end
if ! $:.include?("daemon")
  $: << "daemon"
end
if ! $:.include?("sinatra")
  $: << "sinatra"
end
if ! $:.include?(".")
  $: << "."
end

require 'daemon/OptionHandler'
require 'daemon/util'
require 'logger'
require 'logging'
require 'AppServerConfig'

LogFileName = "logs/sinatra.log"

# Set up initial logger
$logger = makeFileLogger(LogFileName, 5, 5000000)

$appserverConfig = AppServerConfig.new
def parseConfig
  configPath = nil
  
  # Find config file
  configPath = AppServerConfig::findConfigFile
  if ! configPath
    $logger.error "Can't locate config file #{AppServerConfig::TorrentConfigFilename}."
    exit 1
  end

  if ! $appserverConfig.load(configPath)
    $logger.error "Loading configuration file failed"
    exit 1
  end
end

# Parse options
def parseOptions
  opt = OptionHandler.new
  opt.parse

  if opt.opts.has_key?("h") || opt.opts.has_key?("help")
    puts "Usage: bin/start-sinatra [options]"
    puts ""
    puts "Options:"
    puts "  -x: Run in foreground (don't become a daemon)"
    exit 0
  end
  if opt.opts.has_key?("x")
    $optDaemonize = false
  end 
end

$optDaemonize = true
parseOptions
parseConfig

daemonize if $optDaemonize
ENV['RACK_ENV'] = 'production'
# Use rackup to start sinatra. Log error output of rackup to logfile
`rackup -p #{$appserverConfig.listenPort} sinatra/config.ru 2>&1 1>/dev/null`.each_line do |line|
  $logger.error line
end

begin
  FileUtils.rm 'var/sinatra.pid'
rescue
end
