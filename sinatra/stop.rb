#!/usr/bin/env ruby
require 'fileutils'
# Stop sinatra 

pidFilename = "var/sinatra.pid"
if File.exists?(pidFilename)
  File.open(pidFilename,"r") do |file|
    pid = file.read.strip.to_i

    puts "Killing sinatra pid #{pid}"
    begin
      Process.kill "TERM", pid
    rescue
      puts "Killing sinatra failed: #{$!}"
    end

    sleep(1)
    # Check if it really is dead
    begin
      Process.kill 0, pid
      puts "Killing with TERM failed. Sending KILL."
      Process.kill "KILL", pid
    rescue
    end


    FileUtils.rm pidFilename
  end
else
  puts "Sinatra seems to be stopped."
end
