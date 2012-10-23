#!/usr/bin/env ruby

require 'fileutils'

BuildDir = "build"
ExportBaseDir = "export"
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


def cleanRepo?
  `git status -s`.each_line do |line|
    if line =~ /^(..) (.*)/
      status = $1
      filename = $2
      if status =~ /\?/ || status =~ /M/ || status =~ /A/
        # Ignore export/ and libtorrent/ files.
        return false if filename !~ /^export/ && filename !~ /^libtorrent/
      end
    end
  end
  true
end

# Get the version of torrentflow, based on the last git version tag.
def getVersionFromGit
  versions = []
  `git tag -l`.each_line do |line|
    versions.push $1 if line =~ /^v(\d+.\d+.\d+)/
  end
  versions.last
end

# Setup the load path
if ! File.directory?(BuildDir)
  $stderr.puts "Please run this script from the base source directory"
  exit 1
end

mode = ARGV[0]
if ! mode
  puts "Usage #{$0} [binary|source]"
  puts ""
  puts "Use binary to create a binary package, and source to create a source package."
  exit 1
end
mode = mode.to_sym
if mode != :binary && mode != :source
  puts "Invalid mode #{mode}"
  exit 1
end

exportDir = ExportBaseDir + "/binary"
exportDir = ExportBaseDir + "/source" if mode == :source

libtorrentVersion = nil
if mode == :binary
  puts "Building libtorrent extension"
  Dir.chdir("libtorrent") do
    `./extconf.rb`.each_line do |line|
      print line
      libtorrentVersion = $1 if line =~ /Libtorrent version: (.*)/
    end
    exit 1 if ! $?.success?

    if ! libtorrentVersion
      puts "Can't determine libtorrent version from extconf.rb output."
      exit 1
    end

    exit 1 if ! system("make")
  end
  # We only care about the major/minor version of libtorrent, not tiny.
  libtorrentVersion = $1 if libtorrentVersion =~ /^(\d+\.\d+)\.\d+/
end
rubyVersion = RUBY_VERSION
# We only care about the major/minor version of ruby, not tiny.
rubyVersion = $1 if rubyVersion =~ /^(\d+\.\d+)\.\d+/

begin
  FileUtils.rm_r exportDir
rescue
end




cleanRepo = cleanRepo?
if ! cleanRepo
  puts "Warning: Repository is not clean (has untracked files, added files, modified files)."
end

FileUtils.mkdir_p exportDir
version = getVersionFromGit

versionDir = "torrentflow-#{version}"
versionDir += "-UNCLEAN" if ! cleanRepo
versionDir += "-ltr-#{libtorrentVersion}-ruby-#{rubyVersion}" if mode == :binary
packageDir = "#{exportDir}/#{versionDir}"
FileUtils.mkdir packageDir

FileUtils.cp_r "README.md", packageDir
FileUtils.cp_r "daemon", packageDir
FileUtils.cp_r "sinatra", packageDir
FileUtils.cp_r "www", packageDir
FileUtils.cp_r "www-lib", packageDir
FileUtils.cp_r "etc", packageDir
FileUtils.cp_r "build/install.rb", packageDir

FileUtils.mkdir "#{packageDir}/logs"
FileUtils.mkdir "#{packageDir}/var"
libtorrentDir = "#{packageDir}/libtorrent"
FileUtils.mkdir libtorrentDir
if mode == :binary
  FileUtils.cp "libtorrent/libtorrent.so", libtorrentDir
else
  FileUtils.cp Dir.glob("libtorrent/*.i"), libtorrentDir
  FileUtils.cp Dir.glob("libtorrent/extconf.rb"), libtorrentDir
end

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
makeBinScript(binDir, "deluser", "") do |io|
  io.puts "runCommand \'daemon/deluser.rb\'"
end
makeBinScript(binDir, "client", "") do |io|
  io.puts "runCommand \'daemon/client.rb\'"
end
makeBinScript(binDir, "start-sinatra", "") do |io|
  io.puts "runCommand \'sinatra/sdaemon.rb\'"
end
makeBinScript(binDir, "stop-sinatra", "") do |io|
  io.puts "runCommand \'sinatra/stop.rb\'"
end


archiveName = "torrentflow_#{version}"
archiveName += "_UNCLEAN" if ! cleanRepo
archiveName += "_ltr_#{libtorrentVersion}_ruby_#{rubyVersion}" if mode == :binary
archiveName += ".tar.gz"

archive = "#{exportDir}/#{archiveName}"
system "tar czf #{archive} -C '#{exportDir}' #{versionDir}"

puts "Packaged Torrentflow version: #{version} into #{archive}"
