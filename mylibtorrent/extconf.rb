#!/usr/bin/ruby
require 'mkmf'

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

swig = find_executable('swig')

swigOpts = "-DLIBTORRENT_VERSION_MINOR=#{libtorrentMinor}"
print "Generating C++ wrapper file..."
if ! system("./runswig.rb #{swig} #{swigOpts}")
  puts "Failed!"
  exit 1
end
puts "Done"

# When make distclean is run, remove the swig generated sourcefile
$distcleanfiles << "libtorrent.cpp"

create_makefile("libtorrent")
