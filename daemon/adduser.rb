#!/usr/bin/ruby
require 'config'
require 'Authentication'

$config = Config.new
def parseConfig
  
  # Find config file
  configPath = Config.findConfigFile

  if ! configPath
    puts "Error: unable to find configuration file."
    exit 1
  end

  if ! $config.load(configPath)
    exit 1
  end
end

if ARGV.size < 1
  puts "Usage: #{$0} <login>"
  exit 1
end

parseConfig

auth = Authentication.new

pass1 = nil
pass2 = nil
while true
  print "Password: "
  $stdout.flush
  system "stty -echo"
  pass1 = $stdin.gets.chop
  puts ""
  print "Password again: "
  $stdout.flush
  pass2 = $stdin.gets.chop
  puts ""
  system "stty echo"
  if pass1 != pass2
    puts "The passwords don't match. Please enter them again."
  else
    break
  end
end

puts "Adding user #{ARGV[0]}"
begin
  auth.addAccount(ARGV[0], pass1)
  puts "User added"
rescue
  puts "#{$!}"
  puts "User was not added"
end

