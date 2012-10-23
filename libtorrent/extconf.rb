#!/usr/bin/ruby
require 'mkmf'

# Return true if the *.i files or this file have been modified since
# the specified time.
def dependenciesModifiedSince?(time)
  ["extconf.rb"].concat(Dir.glob("*.i")).reduce(false){ |memo, i| memo || File.mtime(i) > time }
end

def runSwig(swig, args)
  system("#{swig} #{args} -autorename -c++ -ruby -o libtorrent.cpp libtorrent.i")
end

idir, ldir = dir_config("libtorrent", "/usr/include", "/usr/lib")
have_library("torrent-rasterbar")
pkg_config("libtorrent-rasterbar")

# Check libtorrent version
libtorrentVersion = [-1,-1,-1]
File.open("#{idir}/libtorrent/version.hpp","r") do |file|
  file.each_line do |line|
    if line =~ /define\s+LIBTORRENT_VERSION_MAJOR\s+(\d+)/
      libtorrentVersion[0] = $1.to_i
    elsif line =~ /define\s+LIBTORRENT_VERSION_MINOR\s+(\d+)/
      libtorrentVersion[1] = $1.to_i
    elsif line =~ /define\s+LIBTORRENT_VERSION_TINY\s+(\d+)/
      libtorrentVersion[2] = $1.to_i
    end
  end
end
if libtorrentVersion.reduce(0){ |memo, n| memo < 0 || n < 0 ? -1 : 0 } < 0
  puts "Can't determine libtorrent version. Got #{libtorrentVersion.join(".")}"
  exit 1
end
puts "Libtorrent version: #{libtorrentVersion.join(".")}"

# Check if makefile already exists and if it is newer than us and the swig files.
if File.exists?("Makefile")
  makefileMtime = File.mtime("Makefile")
  if ! dependenciesModifiedSince?(makefileMtime)
    puts "No dependencies were updated since Makefile was created."
    exit 0
  end
end

if libtorrentVersion[0] != 0 || libtorrentVersion[1] < 14 || libtorrentVersion[1] > 16
  puts "RubyTorrent only supports libtorrent 0.14 - 0.16."
  exit 1
end

if ! File.exists?("libtorrent.cpp") || dependenciesModifiedSince?(File.mtime("libtorrent.cpp"))
  swig = find_executable('swig')
  swigOpts = "-DLIBTORRENT_VERSION_MINOR=#{libtorrentVersion[1]}"
  print "Generating C++ wrapper file..."
  if ! runSwig(swig, swigOpts)
    puts "Failed!"
    exit 1
  end
  puts "Done"
end

# When make distclean is run, remove the swig generated sourcefile
$distcleanfiles << "libtorrent.cpp"

create_makefile("libtorrent")
