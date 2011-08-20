#!/usr/bin/ruby
require 'mkmf'

dir_config("libtorrent", "/usr/include/libtorrent", "/usr/lib")
have_library("torrent-rasterbar")
swig = find_executable('swig')

print "Generating C++ wrapper file..."
if ! system("./runswig.rb #{swig}")
  puts "Failed!"
  exit 1
end
puts "Done"

# When make distclean is run, remove the swig generated sourcefile
$distcleanfiles << "libtorrent.cpp"

create_makefile("libtorrent")
