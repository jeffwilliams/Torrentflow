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
def makeBinScript(path, filename, runDir)
  File.open("#{path}/#{filename}", "w") do |outfile|
    File.open(TemplateFile, "r") do |template|
      template.each_line do |templateLine|
        outline = templateLine
        if templateLine =~ /RunDirectory\s*=/
          outline = "RunDirectory = '#{runDir}'\n"
        end
        outfile.print outline
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
FileUtils.cp_r "build/install.rb", packageDir

libtorrentDir = "#{packageDir}/libtorrent"
FileUtils.mkdir libtorrentDir
FileUtils.cp "libtorrent/extconf.rb", libtorrentDir
FileUtils.cp "libtorrent/libtorrent.cpp", libtorrentDir

binDir = "#{packageDir}/bin"
FileUtils.mkdir binDir
makeBinScript(binDir, "daemon", "daemon") do |io|
  io.puts "runCommand \'./daemon.rb\'"
end
makeBinScript(binDir, "adduser", "daemon") do |io|
  io.puts "runCommand \'./adduser.rb\'"
end
makeBinScript(binDir, "appserver", "") do |io|
  io.puts "runCommand \'sinatra/server.rb\'"
end

archiveName = "torrentflow_#{version}.tar.gz"
archive = "#{ExportDir}/#{archiveName}"
system "tar czf #{archive} -C '#{ExportDir}' #{versionDir}"

puts "Packaged Torrentflow version: #{version} into #{archive}"
