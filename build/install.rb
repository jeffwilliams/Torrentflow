#!/usr/bin/env ruby
require 'fileutils'

Version = "0.0"

RequiredBinaries = ["g++", "make", "gem"]
RequiredGems = ["sinatra", "haml", "json", "mahoro"]
RecommendedGems = ["mongo"]
InstallLog = "install.log"

# This script is used to install torrentflow from the torrentflow distribution package.

# Simple option handling class.
# Create a new instance, which automatically reads ARGV, call parse, and then
# access the opts hash to access options, and the args array to access args.
class OptionHandler
	
	class Option
		def initialize(optname)
			@name = optname
			@value = nil
		end

		attr_reader :name
		attr_accessor :value
	end	

	def initialize
		setArgv(ARGV)
	end
	
	def setArgv(argv)
		@raw = argv
	end

	InOptions = 0
	AfterOptions = 1
	def parse
		@opts = {}
		@args = []
		state = InOptions
		lastOpt = nil
		@raw.each{ |arg|
			if arg[0..0] == '-'
				if arg == '--' 	# -- signifies that the rest of the arguments are not options	
					state = AfterOptions
				else
					s = 1
					s = 2 if arg[0..1] == '--'
					opt = arg[s,arg.length]
					opts[opt] = Option.new(opt)
					lastOpt = opts[opt]
				end
			else
				if lastOpt && state == InOptions
					lastOpt.value = arg
					lastOpt = nil
				else
					# Must be into the arguments
					args.push arg
					state = AfterOptions
				end
			end
		}
	end 
	
	def show
		puts "Options: "
		opts.each{ |key, value|
			puts " #{key} => #{value.name} = #{value.value}"
		}
		puts "Arguments: "
		args.each{ |arg|
			puts " '#{arg}'"
		}
	
	end

	attr_reader :opts
	attr_reader :args
end

def setTorrentflowHome(filepath)
  bak = "#{filepath}.bak"
  FileUtils.cp filepath, bak
  File.open(filepath, "w") do |outfile|
    File.open(bak, "r") do |infile|
      infile.each_line do |line|
        if line =~ /TorrentflowHome\s+=/
          line = "TorrentflowHome = '#{Dir.pwd}'\n"
        end
        outfile.print line
      end
    end
  end
  FileUtils.rm bak
end

def commandAvailable?(cmd)
  # Linux specific
  system("#{cmd} >/dev/null 2>&1")
  return $?.exitstatus != 127
end

def gemInstalled?(gem)
  system("gem list -i '#{gem}' >/dev/null 2>&1")
end

opthandler = OptionHandler.new
opthandler.parse
if opthandler.opts["help"] || opthandler.opts["h"] 
  puts "Usage: install.rb [options] [installation directory]"
  puts "" 
  puts "Options:"
  puts "  --help, -h: Show this help"
  exit 0
end

begin
  FileUtils.rm InstallLog
rescue
end

print "Checking requirements..."
$stdout.flush

# Check requirements
RequiredBinaries.each do |cmd|
  if ! commandAvailable?(cmd)
    puts "Torrentflow requires #{cmd} to be installed, but it's not runnable. Aborting install."
    exit 1
  end
end 

RequiredGems.each do |gem|
  if ! gemInstalled?(gem)
    puts "Torrentflow requires the ruby gem #{gem} to be installed, but it's not installed. Aborting install."
    exit 1
  end
end 

RecommendedGems.each do |gem|
  if ! gemInstalled?(gem)
    puts "Torrentflow recommends that the ruby gem #{gem} should be installed, but it's not installed. Continuing anyhow."
  end
end

puts "OK"

# Build extension
if ! File.exists? "libtorrent/libtorrent.so"
  print "Compiling ruby extension for libtorrent-rasterbar..."
  $stdout.flush
  Dir.chdir("libtorrent") do 
    if ! system("ruby extconf.rb >> ../#{InstallLog} 2>&1")
      puts "FAILED"
      puts "An error occurred when running 'ruby extconf.rb' in directory 'libtorrent'. Aborting install."
      puts "Check #{InstallLog} for details."
      exit 1
    end
    
    if ! system("make >> ../#{InstallLog} 2>&1")
      puts "FAILED"
      puts "An error occurred when running make in directory 'libtorrent'. Aborting install."
      puts "Check #{InstallLog} for details."
      exit 1
    end
  end
  puts "OK"
end

print "Updating TorrentflowHome in bin/ scripts..."
$stdout.flush
Dir.new("bin/").each do |f|
  next if f[0,1] == '.'
  path = "bin/#{f}"
  setTorrentflowHome(path)
end
puts "OK"

puts ""
puts "Installation completed. You can now run torrentflow from this directory."
