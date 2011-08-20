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

if ARGV.size < 2
  puts "Usage: #{$0} <login> <password>"
  exit 1
end

parseConfig

auth = Authentication.new

puts "Adding user #{ARGV[0]}/#{ARGV[1]}"
auth.addAccount(ARGV[0], ARGV[1])

puts "User added"
