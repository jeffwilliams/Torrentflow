#!/usr/bin/ruby
require 'mkmf'

# Return true if the *.i files or this file have been modified since
# the specified time.
def dependenciesModifiedSince?(time)
  ["extconf.rb"].concat(Dir.glob("*.i")).reduce(false){ |memo, i| memo || File.mtime(i) > time }
end

# Check if makefile already exists and if it is newer than us and the swig files.
if File.exists?("Makefile")
  makefileMtime = File.mtime("Makefile")
  if ! dependenciesModifiedSince?(makefileMtime)
    puts "No dependencies were updated since Makefile was created."
    exit 0
  end
end


dir_config("libtorrent", "/usr/include/libtorrent", "/usr/lib")
have_library("torrent-rasterbar")

# Check libtorrent version
version = `pkg-config --modversion libtorrent-rasterbar`
libtorrentMajor = nil
libtorrentMinor = nil
if version =~ /([^\.]+)\.([^\.]+)\..*/
  libtorrentMajor = $1
  libtorrentMinor = $2
  puts "libtorrent-rasterbar version: #{libtorrentMajor}.#{libtorrentMinor}"
end

if !libtorrentMajor || !libtorrentMinor
  puts "Parsing libtorrent version using pkg-config failed."
  exit 1
end

if !libtorrentMajor == "0" || ! (libtorrentMinor == "13" || libtorrentMinor == "14")
  puts "RubyTorrent only supports libtorrent 0.13 or 0.14 (each minor release breaks interface compatibility)"
  exit 1
end

if ! File.exists?("libtorrent.cpp") 
  cppMtime = File.mtime("libtorrent.cpp")
  if dependenciesModifiedSince?(cppMtime)
    swig = find_executable('swig')
    swigOpts = "-DLIBTORRENT_VERSION_MINOR=#{libtorrentMinor}"
    print "Generating C++ wrapper file..."
    if ! system("./runswig.rb #{swig} #{swigOpts}")
      puts "Failed!"
      exit 1
    end
    puts "Done"
  end
end


# When make distclean is run, remove the swig generated sourcefile
$distcleanfiles << "libtorrent.cpp"

create_makefile("libtorrent")
