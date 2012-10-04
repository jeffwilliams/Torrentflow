%{
#include "libtorrent/bencode.hpp"
%}

/*
* Entry loading taken from Joshua Bassett's libtorrent-ruby.
* load_entry functions are able to build a libtorrent::entry from
* a path.
*/
%{
#include <fstream>
#include <iterator>
#include "libtorrent/bencode.hpp"
#include "libtorrent/entry.hpp"

static libtorrent::entry load_entry(std::istream& in) {
  in.unsetf(std::ios_base::skipws);
  try {
    libtorrent::entry e = libtorrent::bdecode(std::istream_iterator<char>(in), std::istream_iterator<char>());
    return e;
  } catch (libtorrent::invalid_encoding) {
    rb_raise(rb_eStandardError, "Invalid torrent");
  }
}

static libtorrent::entry load_entry(const char* path) {
  std::ifstream in(path, std::ios_base::binary);
  if (!in)
    rb_raise(rb_eStandardError, "Torrent file does not exist");
  return load_entry(in);
}

static void save_entry(const libtorrent::entry& e, const char* path) {
  std::ofstream out(path, std::ios_base::binary);
  libtorrent::bencode(std::ostream_iterator<char>(out), e);
}
%}
