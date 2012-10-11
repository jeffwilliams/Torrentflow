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
    FileUtils.rm pidFilename
  end
else
  puts "Sinatra seems to be stopped."
end
