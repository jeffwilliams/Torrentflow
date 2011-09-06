#!/usr/bin/ruby
swig = "swig"
args = ""
swig = ARGV.shift if !ARGV.empty?
args = ARGV.join(" ") if !ARGV.empty?

if system("#{swig} #{args} -autorename -c++ -ruby -o libtorrent.cpp libtorrent.i")
  exit 0
else
  exit 1
end
