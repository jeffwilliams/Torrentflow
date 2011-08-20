#!/usr/bin/ruby
require 'config'
require 'Authentication'

$config = Config.new
TorrentConfigFilename = "rubytorrentdeamon.conf"
def parseConfig
  configPath = nil
  
  # Find config file
  if File.exists?(TorrentConfigFilename)
    configPath = TorrentConfigFilename
  elsif File.exists?("/etc/#{TorrentConfigFilename}")
    configPath = "/etc/#{TorrentConfigFilename}"
  else
    $syslog.info "Error: Can't locate config file #{TorrentConfigFilename} in the current dir or in /etc."
    exit 1
  end

  if ! $config.load(configPath)
    exit 1
  end
end

parseConfig

auth = Authentication.new

if ! File.exists? 'passwd'
  auth.addAccount('tim','conga')
end

def doauth(auth, user, pass)
  if auth.authorize(user,pass)
    puts "Auth succeeded"
  else
    puts "Auth failed"
  end
end


doauth auth, 'tim','conga'
doauth auth, 'tim','congaa'
