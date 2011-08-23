#!/usr/bin/ruby

require 'daemonclient'

commands = 
{
  "list" => "List torrents",
  "add" => "Add a torrent to the session. Pass the path to the torrent",
  "del" => "Delete a torrent. Pass the name of the torrent",
  "get" => "Get a torrent and copy it to the torrents dir",
  "kill" => "Terminate the torrent daemon",
  "alerts" => "Get the latest alerts. If a second parameter is specified, only alerts for that torrent name are returned",
  "fsinfo" => "Get fsinfo"
}

if ARGV.size <= 0 || !commands.has_key?(ARGV[0])
  puts "Usage: #{$0} <command>"
  puts
  puts "Valid commands are: "
  commands.each{ |k,v|
    puts "  #{k}: #{v}"
  }
  exit 1
end


client = nil
begin
  client = DaemonClient.new("localhost", 3000, 2)
rescue
  puts "Connecting failed: #{$!}"
  exit 1
end

if ARGV[0] == "list"
  begin
    torrents = client.listTorrents([:name, :creator, :progress, :state])
  rescue
    puts "Operation failed: #{$!}"
    puts $!.backtrace.join("\n")
  end
  if torrents
    torrents.each{ |t|
      puts "Torrent: "
      t.values.each{ |k,v|
        puts "  #{k.to_s}=#{v}"
      }
    }
  else
    puts "Got null response from server."
  end
elsif ARGV[0] == "add"
  if ARGV.size < 2
    puts "The add command expects the path to a file."
    exit 1
  end

  begin
    path = client.addTorrent(ARGV[1]);
  rescue
    puts "Operation failed: #{$!}"
    puts $!.backtrace.join("\n")
  end
elsif ARGV[0] == "del"
  if ARGV.size < 2
    puts "The del command expects the name of a file."
    exit 1
  end

  begin
    torrents = client.delTorrent(ARGV[1]);
  rescue
    puts "Operation failed: #{$!}"
    puts $!.backtrace.join("\n")
  end
elsif ARGV[0] == "get"
  if ARGV.size < 2
    puts "The get command expects the name of a file, or a URL."
    exit 1
  end

  begin
    type = :disk
    type = :url if ARGV[1] =~ /http:\/\//
    rc = client.getTorrent(ARGV[1], type)
    if ! rc
      puts "Getting torrent failed: #{client.errorMsg}"
    else
      puts "Local path: #{rc}" 
    end

  rescue
    puts "Operation failed: #{$!}"
    puts $!.backtrace.join("\n")
  end
elsif ARGV[0] == "kill"
  if client.terminateDaemon
    puts "Terminated daemon"
  else
    puts "Terminating daemon failed"
  end
elsif ARGV[0] == "alerts"
  torrentName = nil
  torrentName = ARGV[1] if ARGV.size > 1
  rc = client.getAlerts(torrentName)
  if rc
    puts "Alerts:"
    rc.each{ |e|
      puts "  " + e
    }
  else
    puts "Getting alerts failed"
  end
elsif ARGV[0] == "fsinfo"
  torrentName = nil
  torrentName = ARGV[1] if ARGV.size > 1
  rc = client.getFsInfo
  if rc
    puts "Filesystem info:"
    puts "freeSpace: #{rc.freeSpace}"
    puts "usedSpace: #{rc.usedSpace}"
    puts "totalSpace: #{rc.totalSpace}"
    puts "usePercent: #{rc.usePercent}"
  else
    puts "Getting fs info failed"
  end
end

