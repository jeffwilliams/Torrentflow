%{
#include <sstream>
#include "libtorrent/torrent_info.hpp"
#include "boost/filesystem/operations.hpp"
#include "stdio.h"
%}

namespace libtorrent {

  struct file_entry
  {
#if LIBTORRENT_VERSION_MINOR <= 15
    boost::filesystem::path path;
#elif LIBTORRENT_VERSION_MINOR > 15
    std::string path;
#endif
    size_type offset;
    size_type size;
  };

  struct file_slice
  {
    int file_index;
    size_type offset;
    size_type size;
  };

  struct announce_entry
  {
    announce_entry(std::string const& u);
    std::string url;
    int tier;
  };

  class torrent_info
  {
  public:

    torrent_info(sha1_hash const& info_hash);
    torrent_info(entry const& torrent_file);
    ~torrent_info();

    const std::string& comment() const;

    const std::string& creator() const;

    void add_tracker(std::string const& url, int tier = 0);
    void add_url_seed(std::string const& url);

#if LIBTORRENT_VERSION_MINOR < 16
    boost::optional<boost::posix_time::ptime> creation_date() const;
#elif LIBTORRENT_VERSION_MINOR >= 16
    boost::optional<time_t> creation_date() const;
#endif

    std::vector<file_slice> map_block(int piece, size_type offset, int size) const;
    peer_request map_file(int file, size_type offset, int size) const;

    %typemap(out) std::vector<std::string> const& url_seeds() {
      VALUE array = rb_ary_new();
      for (std::vector<std::string>::const_iterator i = $1->begin();
           i != $1->end(); ++i) {
        rb_ary_push(array, rb_str_new2(i->c_str()));
      }
      $result = array;
    }

    std::vector<std::string> const& url_seeds() const;

    const file_entry& file_at(int index) const;

    %typemap(out) const std::vector<announce_entry>& trackers() {
      VALUE array = rb_ary_new();
      for (std::vector<libtorrent::announce_entry>::const_iterator i = $1->begin();
           i != $1->end(); ++i) {
        libtorrent::announce_entry* p = new libtorrent::announce_entry(*i);
        VALUE obj = SWIG_NewPointerObj(SWIG_as_voidptr(p), SWIGTYPE_p_libtorrent__announce_entry, SWIG_POINTER_OWN);
        if (obj != Qnil) rb_ary_push(array, obj);
      }
      return array;
    }

    const std::vector<announce_entry>& trackers() const;

    size_type total_size() const;
    size_type piece_length() const;
    int num_files() const;
    int num_pieces() const;
    const sha1_hash& info_hash() const;
    const std::string& name() const;

    %rename("valid?") is_valid() const;
    bool is_valid() const;

    size_type piece_size(int index) const;
    const sha1_hash& hash_for_piece(int index) const;

    %extend {

      VALUE files() const {
        VALUE array = rb_ary_new();
        for(int i = 0; i < self->num_files(); i++)
        {
#if LIBTORRENT_VERSION_MINOR <= 15
          VALUE rubyString = rb_str_new(self->file_at(i).path.string().c_str(), self->file_at(i).path.string().length());
#elif LIBTORRENT_VERSION_MINOR > 15
          VALUE rubyString = rb_str_new(self->file_at(i).path.c_str(), self->file_at(i).path.length());
#endif
          if (rubyString != Qnil) rb_ary_push(array, rubyString);
        }

        return array;
      }

      static libtorrent::torrent_info load(const char* path) const {
        try {
          /* return libtorrent::torrent_info(load_entry(path)); */
#if LIBTORRENT_VERSION_MINOR < 16
            return libtorrent::torrent_info(boost::filesystem::path(path));
#elif LIBTORRENT_VERSION_MINOR >= 16
            std::string strpath(path);
FILE* file = fopen("/tmp/debug","w");
if ( file ) {
  fprintf(file, "path: '%s'\n", strpath.c_str());
}
fclose(file);
            return libtorrent::torrent_info(strpath);
#endif
        
        } 
        catch(libtorrent::invalid_torrent_file)
        {
          rb_raise(rb_eStandardError, "Invalid torrent file in TorrentInfo::load");
        }  
        catch(...)
        {
          rb_raise(rb_eStandardError, "Invalid torrent file (2) in TorrentInfo::load");
        }  
      }

    }

  };
}
