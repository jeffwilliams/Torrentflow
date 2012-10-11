#!/usr/bin/env ruby

require 'fileutils'

BuildDir = "build"
ExportDir = "export"
VersionFile = "#{BuildDir}/VERSION"
TemplateFile = "#{BuildDir}/script-template"

# Create a script that will live under the bin/ subdirectory. This function
# yields an io to a passed block into which the block should write the script 
# contents. The header of the script is taken from the TemplateFile.
# runDir: the subdirectory under torrentflow home that should be used as the CWD when  
# the script is run.
def makeBinScript(path, filename, runDir, requires = [])
  File.open("#{path}/#{filename}", "w") do |outfile|
    File.open(TemplateFile, "r") do |template|
      lineno = 0
      template.each_line do |templateLine|
        lineno += 1
        outline = templateLine
        if templateLine =~ /RunDirectory\s*=/
          outline = "RunDirectory = '#{runDir}'\n"
        end
        outfile.print outline
        if lineno == 2
          # Add all require statements after line 1
          requires.each do |r|
            outfile.puts "require '#{r}'"
          end
        end
      end
      yield outfile if block_given?
    end
  end
  
  FileUtils.chmod 0755, "#{path}/#{filename}"
end


# Setup the load path
if ! File.directory?(BuildDir)
  $stderr.puts "Please run this script from the base source directory"
  exit 1
end

begin
  FileUtils.rm_r ExportDir
rescue
end

FileUtils.mkdir ExportDir
version = File.read(VersionFile).strip

versionDir = "torrentflow-#{version}"
packageDir = "#{ExportDir}/#{versionDir}"
FileUtils.mkdir packageDir

FileUtils.cp_r "daemon", packageDir
FileUtils.cp_r "sinatra", packageDir
FileUtils.cp_r "www", packageDir
FileUtils.cp_r "www-lib", packageDir
FileUtils.cp_r "etc", packageDir
FileUtils.cp_r "build/install.rb", packageDir

libtorrentDir = "#{packageDir}/libtorrent"
FileUtils.mkdir libtorrentDir
FileUtils.mkdir "#{packageDir}/logs"
FileUtils.mkdir "#{packageDir}/var"
FileUtils.cp "libtorrent/extconf.rb", libtorrentDir
FileUtils.cp "libtorrent/libtorrent.cpp", libtorrentDir

binDir = "#{packageDir}/bin"
FileUtils.mkdir binDir
makeBinScript(binDir, "start-daemon", "") do |io|
  io.puts "runCommand \'daemon/daemon.rb\'"
end
makeBinScript(binDir, "stop-daemon", "") do |io|
  io.puts "runCommand \'daemon/client.rb kill\'"
end
makeBinScript(binDir, "adduser", "") do |io|
  io.puts "runCommand \'daemon/adduser.rb\'"
end
makeBinScript(binDir, "client", "") do |io|
  io.puts "runCommand \'daemon/client.rb\'"
end
makeBinScript(binDir, "start-sinatra", "", ['fileutils']) do |io|
func = <<FUNC
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
FUNC
  # We need to add our requires after we change directory
  ['daemon/OptionHandler', 'daemon/util'].each do |l|
    io.puts "require '#{l}'"
  end

  io.puts func
  io.puts
  io.puts "$optDaemonize = true"
  io.puts "parseOptions"
  io.puts "daemonize if $optDaemonize"

  io.puts "ENV['RACK_ENV'] = 'production'"
  io.puts "system 'rackup -p 4567 sinatra/config.ru'"
  io.puts "begin"
  io.puts "  FileUtils.rm 'var/sinatra.pid'"
  io.puts "rescue"
  io.puts "end"
end
makeBinScript(binDir, "stop-sinatra", "") do |io|
  io.puts "runCommand \'sinatra/stop.rb\'"
end


archiveName = "torrentflow_#{version}.tar.gz"
archive = "#{ExportDir}/#{archiveName}"
system "tar czf #{archive} -C '#{ExportDir}' #{versionDir}"

puts "Packaged Torrentflow version: #{version} into #{archive}"
