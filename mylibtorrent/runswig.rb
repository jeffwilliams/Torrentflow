#!/usr/bin/ruby
swig = "swig"
if ARGV.length > 0
  swig = ARGV[0]
end
if system("#{swig} -autorename -c++ -ruby -o libtorrent.cpp libtorrent.i")
  exit 0
else
  exit 1
end
